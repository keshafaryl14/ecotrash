import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/scan_record.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:ecotrash/features/smart_scan/domain/repositories/scan_history_repository.dart';
import 'package:ecotrash/features/smart_scan/presentation/providers/scan_providers.dart';
import 'package:ecotrash/features/smart_scan/presentation/scan_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartScanPage extends ConsumerStatefulWidget {
  const SmartScanPage({super.key});

  @override
  ConsumerState<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends ConsumerState<SmartScanPage>
    with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  CameraController? _cameraController;
  bool _cameraPermissionGranted = false;
  bool _cameraPermanentlyDenied = false;
  bool _cameraInitializing = true;
  bool _isProcessing = false;
  String? _cameraError;
  String? _galleryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _cameraPermissionGranted) {
      _startCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _cameraInitializing = true;
        _cameraError = null;
      });
    }

    try {
      var permission = await Permission.camera.status;
      if (permission.isDenied) {
        permission = await Permission.camera.request();
      }

      if (!permission.isGranted) {
        if (mounted) {
          setState(() {
            _cameraPermissionGranted = false;
            _cameraPermanentlyDenied =
                permission.isPermanentlyDenied || permission.isRestricted;
            _cameraInitializing = false;
          });
        }
        return;
      }

      _cameraPermissionGranted = true;
      await _startCamera();
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraError = 'Kamera tidak dapat dibuka: $error';
          _cameraInitializing = false;
        });
      }
    }
  }

  Future<void> _startCamera() async {
    CameraController? previous = _cameraController;
    _cameraController = null;
    await previous?.dispose();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = 'Kamera tidak ditemukan di perangkat ini.';
            _cameraInitializing = false;
          });
        }
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraInitializing = false;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (mounted) {
        setState(() {
          _cameraError =
              'Kamera gagal dimulai: ${error.description ?? error.code}';
          _cameraInitializing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraError = 'Kamera tidak dapat dibuka: $error';
          _cameraInitializing = false;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isProcessing) {
      return;
    }

    try {
      final photo = await controller.takePicture();
      await _classifyPhoto(photo);
    } on CameraException catch (error) {
      _showMessage('Foto gagal diambil: ${error.description ?? error.code}');
    } catch (error) {
      _showMessage('Foto gagal diproses: $error');
    }
  }

  Future<void> _chooseFromGallery() async {
    if (_isProcessing) {
      return;
    }
    setState(() => _galleryError = null);

    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        await _classifyPhoto(photo);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _galleryError = 'Foto dari galeri tidak dapat dibuka: $error',
        );
      }
    }
  }

  Future<void> _classifyPhoto(XFile photo) async {
    if (mounted) {
      setState(() {
        _isProcessing = true;
        _galleryError = null;
      });
    }

    try {
      final imageBytes = await File(photo.path).readAsBytes();
      final classification = await ref
          .read(wasteClassifierProvider)
          .classify(imageBytes);
      var historySaved = true;
      String? historyError;

      try {
        await ref
            .read(scanHistoryRepositoryProvider)
            .save(
              ScanRecord(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                scannedAt: DateTime.now(),
                category: classification.category,
                confidence: classification.confidence,
                specificType: classification.specificType,
                hasEconomicValue: classification.hasEconomicValue,
              ),
            );
        ref.invalidate(scanHistoryProvider);
      } on ScanHistoryException catch (error) {
        historySaved = false;
        historyError = error.message;
      }

      if (mounted) {
        await context.push(
          AppRoutes.scanResult,
          extra: ScanResultPageArgs(
            imageBytes: imageBytes,
            classification: classification,
            historySaved: historySaved,
            historyError: historyError,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Foto tidak dapat dikenali: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openSettings() async {
    final opened = await openAppSettings();
    if (!opened && mounted) {
      _showMessage('Pengaturan aplikasi tidak dapat dibuka.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scanHistoryProvider);
    final controller = _cameraController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Scan'),
        actions: [
          IconButton(
            key: const Key('scan-history-refresh'),
            tooltip: 'Muat ulang riwayat',
            onPressed: () => ref.invalidate(scanHistoryProvider),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Kenali sampah, pilah dengan benar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Arahkan kamera ke satu jenis sampah atau pilih foto dari galeri.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _buildCameraPreview(context, controller),
          const SizedBox(height: 14),
          if (_isProcessing) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              'Menganalisis foto dan menyimpan hasil...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('scan-take-picture'),
                  onPressed:
                      controller != null &&
                          controller.value.isInitialized &&
                          !_isProcessing
                      ? _takePicture
                      : null,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Ambil foto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('scan-pick-gallery'),
                  onPressed: _isProcessing ? null : _chooseFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih galeri'),
                ),
              ),
            ],
          ),
          if (_galleryError != null) ...[
            const SizedBox(height: 8),
            Text(
              _galleryError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 28),
          Text('Riwayat scan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          history.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _HistoryMessage(
              icon: Icons.error_outline,
              message: 'Riwayat scan gagal dimuat: $error',
            ),
            data: (records) => records.isEmpty
                ? const _HistoryMessage(
                    icon: Icons.photo_camera_back_outlined,
                    message: 'Belum ada riwayat scan. Hasil scan akan tampil di sini.',
                  )
                : Column(
                    children: [
                      for (final record in records.take(20))
                        _HistoryTile(record: record),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(
    BuildContext context,
    CameraController? controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget content;
    if (_cameraInitializing) {
      content = const Center(child: CircularProgressIndicator());
    } else if (!_cameraPermissionGranted) {
      content = _PermissionPrompt(
        permanentlyDenied: _cameraPermanentlyDenied,
        onRetry: _initializeCamera,
        onSettings: _openSettings,
      );
    } else if (controller != null && controller.value.isInitialized) {
      content = CameraPreview(controller);
    } else {
      content = _CameraErrorPrompt(
        message: _cameraError ?? 'Pratinjau kamera belum tersedia.',
        onRetry: _initializeCamera,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (_isProcessing)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({
    required this.permanentlyDenied,
    required this.onRetry,
    required this.onSettings,
  });

  final bool permanentlyDenied;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, size: 40),
          const SizedBox(height: 10),
          Text(
            permanentlyDenied
                ? 'Izin kamera ditolak permanen. Aktifkan izin dari pengaturan aplikasi.'
                : 'EcoTrash memerlukan izin kamera untuk mengambil foto sampah.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (permanentlyDenied)
            OutlinedButton(
              onPressed: onSettings,
              child: const Text('Buka Pengaturan'),
            )
          else
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _CameraErrorPrompt extends StatelessWidget {
  const _CameraErrorPrompt({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, size: 40),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Coba buka kamera lagi'),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context)
        .formatShortDate(record.scannedAt);
    final category = switch (record.category) {
      WasteCategory.organic => 'Organik',
      WasteCategory.inorganic => 'Anorganik',
      WasteCategory.hazardous => 'B3',
    };

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.recycling_outlined)),
        title: Text(record.specificType),
        subtitle: Text('$category • $date'),
        trailing: Text('${(record.confidence * 100).round()}%'),
      ),
    );
  }
}
