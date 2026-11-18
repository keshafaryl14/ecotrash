import 'dart:async';

import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/services/location_service.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/providers/waste_bank_providers.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/waste_bank_list_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class WasteBankDirectoryPage extends ConsumerStatefulWidget {
  const WasteBankDirectoryPage({super.key});

  @override
  ConsumerState<WasteBankDirectoryPage> createState() =>
      _WasteBankDirectoryPageState();
}

class _WasteBankDirectoryPageState
    extends ConsumerState<WasteBankDirectoryPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(wasteBankDirectoryProvider);

    return directory.when(
      loading: () => const _DirectoryLoading(),
      error: (error, stackTrace) => _LocationErrorView(
        error: error,
        onRetry: () => ref.invalidate(wasteBankDirectoryProvider),
        onOpenSettings: _openLocationSettings,
      ),
      data: (data) => _buildMap(context, data),
    );
  }

  Widget _buildMap(BuildContext context, WasteBankDirectoryData data) {
    final userPoint = LatLng(
      data.userLocation.latitude,
      data.userLocation.longitude,
    );
    final markers = <Marker>[
      Marker(
        point: userPoint,
        width: 48,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.white),
        ),
      ),
      for (final bank in data.banks)
        Marker(
          point: LatLng(bank.location.latitude, bank.location.longitude),
          width: 48,
          height: 56,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            key: Key('waste-bank-marker-${bank.id}'),
            onTap: () => _openBankDetail(bank),
            child: Tooltip(
              message: bank.name,
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF2E7D32),
                size: 42,
              ),
            ),
          ),
        ),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userPoint,
            initialZoom: 14,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ecotrash.ecotrash',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 8,
          left: 8,
          child: SimpleAttributionWidget(
            alignment: Alignment.topLeft,
            source: const Text('OpenStreetMap contributors'),
            onTap: _openAttribution,
          ),
        ),
        Positioned(
          top: 12,
          right: 16,
          child: SafeArea(
            child: FloatingActionButton.small(
              key: const Key('map-current-location'),
              heroTag: 'map-current-location',
              tooltip: 'Kembali ke lokasi saya',
              onPressed: () => _mapController.move(userPoint, 15),
              child: const Icon(Icons.my_location),
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.2,
          maxChildSize: 0.84,
          builder: (context, scrollController) => Material(
            elevation: 12,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: WasteBankListPanel(
              banks: data.banks,
              center: data.userLocation,
              scrollController: scrollController,
              onBankSelected: _openBankDetail,
            ),
          ),
        ),
      ],
    );
  }

  void _openBankDetail(WasteBank bank) {
    final location = AppRoutes.bankDetail.replaceFirst(':id', bank.id);
    unawaited(context.push(location, extra: bank));
  }

  void _openAttribution() {
    unawaited(_launchAttribution());
  }

  Future<void> _launchAttribution() async {
    try {
      final launched = await launchUrl(
        Uri.https('www.openstreetmap.org', '/copyright'),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showMessage('Halaman atribusi OpenStreetMap tidak dapat dibuka.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Halaman atribusi OpenStreetMap gagal dibuka: $error');
      }
    }
  }

  Future<void> _openLocationSettings(LocationException? error) async {
    final service = ref.read(locationServiceProvider);
    try {
      final opened = error?.failure == LocationFailure.serviceDisabled
          ? await service.openLocationSettings()
          : await service.openAppSettings();
      if (!opened && mounted) {
        _showMessage('Pengaturan lokasi tidak dapat dibuka.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Pengaturan lokasi gagal dibuka: $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DirectoryLoading extends StatelessWidget {
  const _DirectoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Peta Bank Sampah Terdekat'),
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text('Mengambil lokasi perangkat...'),
        ],
      ),
    );
  }
}

class _LocationErrorView extends StatelessWidget {
  const _LocationErrorView({
    required this.error,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final Object error;
  final VoidCallback onRetry;
  final ValueChanged<LocationException?> onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final LocationException? locationError = switch (error) {
      LocationException value => value,
      _ => null,
    };
    final message =
        locationError?.message ?? 'Lokasi tidak dapat diakses: $error';
    final settingsLabel =
        locationError?.failure == LocationFailure.serviceDisabled
        ? 'Nyalakan GPS'
        : 'Buka Pengaturan Izin';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              locationError?.failure == LocationFailure.serviceDisabled
                  ? Icons.location_disabled_outlined
                  : Icons.location_off_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Peta Bank Sampah Terdekat',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (locationError?.failure ==
                    LocationFailure.permissionPermanentlyDenied ||
                locationError?.failure == LocationFailure.serviceDisabled)
              OutlinedButton.icon(
                onPressed: () => onOpenSettings(locationError),
                icon: const Icon(Icons.settings_outlined),
                label: Text(settingsLabel),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('waste-bank-location-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
