import 'dart:typed_data';

import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/features/smart_scan/domain/entities/waste_classification.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_order_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScanResultPageArgs {
  const ScanResultPageArgs({
    required this.imageBytes,
    required this.classification,
    required this.historySaved,
    this.historyError,
  });

  final Uint8List imageBytes;
  final WasteClassification classification;
  final bool historySaved;
  final String? historyError;
}

class ScanResultPage extends ConsumerWidget {
  const ScanResultPage({required this.args, super.key});

  final ScanResultPageArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classification = args.classification;
    final theme = Theme.of(context);
    final eco =
        theme.extension<EcoColors>() ?? EcoColors.from(theme.colorScheme);
    final colors = _categoryColors(eco, classification.category);
    final animationsEnabled = ref.watch(earthAnimationsEnabledProvider);
    final confidencePercent = (classification.confidence * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Smart Scan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.memory(
                args.imageBytes,
                key: const Key('scan-result-image'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
          if (!args.historySaved) ...[
            const SizedBox(height: 16),
            _ResultNotice(
              key: const Key('scan-history-save-warning'),
              icon: Icons.warning_amber_outlined,
              message:
                  args.historyError ??
                  'Hasil tampil, tetapi riwayat scan tidak dapat disimpan.',
              isError: true,
            ),
          ],
          const SizedBox(height: 20),
          Card(
            color: colors.container,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: animationsEnabled ? 0.6 : 1, end: 1),
                    duration:
                        animationsEnabled &&
                            !MediaQuery.of(context).disableAnimations
                        ? const Duration(milliseconds: 450)
                        : Duration.zero,
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Icon(
                      _categoryIcon(classification.category),
                      size: 28,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classification.category.label,
                          key: const Key('scan-result-category'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          classification.specificType,
                          key: const Key('scan-result-type'),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.foreground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tingkat keyakinan: $confidencePercent%',
            key: const Key('scan-result-confidence'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: classification.confidence,
            color: colors.foreground,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          if (classification.needsRetake) ...[
            const SizedBox(height: 16),
            _ResultNotice(
              icon: Icons.photo_camera_outlined,
              message:
                  'Keyakinan masih rendah. Coba foto ulang di tempat terang, '
                  'pastikan sampah terlihat utuh, dan gunakan latar sederhana.',
            ),
          ],
          const SizedBox(height: 20),
          _InstructionCard(
            title: 'Cara memilah',
            icon: Icons.rule_outlined,
            content: classification.sortingInstructions,
          ),
          const SizedBox(height: 12),
          _InstructionCard(
            title: 'Cara mengolah',
            icon: Icons.recycling_outlined,
            content: classification.processingInstructions,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                classification.hasEconomicValue
                    ? Icons.paid_outlined
                    : Icons.info_outline,
              ),
              title: const Text('Nilai ekonomi'),
              subtitle: Text(
                classification.hasEconomicValue
                    ? 'Berpotensi memiliki nilai jual di bank sampah.'
                    : 'Tidak bernilai ekonomi; ikuti panduan pembuangan setempat.',
                key: const Key('scan-result-economic-value'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('scan-result-bank-button'),
            onPressed: () => context.go(AppRoutes.map),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Setor ke Bank Sampah'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('scan-result-pickup-button'),
            onPressed: () => context.go(
              AppRoutes.pickupNew,
              extra: PickupFormPrefill.fromScannedType(
                classification.specificType,
              ),
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Jadwalkan Penjemputan'),
          ),
          TextButton.icon(
            key: const Key('scan-result-retake-button'),
            onPressed: () => context.go(AppRoutes.scan),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Pindai ulang'),
          ),
        ],
      ),
    );
  }
}

extension on WasteCategory {
  String get label => switch (this) {
    WasteCategory.organic => 'Organik',
    WasteCategory.inorganic => 'Anorganik',
    WasteCategory.hazardous => 'B3',
  };
}

_ScanCategoryColors _categoryColors(EcoColors colors, WasteCategory category) =>
    switch (category) {
      WasteCategory.organic => _ScanCategoryColors(
        colors.organicContainer,
        colors.onOrganicContainer,
      ),
      WasteCategory.inorganic => _ScanCategoryColors(
        colors.inorganicContainer,
        colors.onInorganicContainer,
      ),
      WasteCategory.hazardous => _ScanCategoryColors(
        colors.hazardousContainer,
        colors.onHazardousContainer,
      ),
    };

IconData _categoryIcon(WasteCategory category) => switch (category) {
  WasteCategory.organic => Icons.compost_outlined,
  WasteCategory.inorganic => Icons.recycling_outlined,
  WasteCategory.hazardous => Icons.warning_amber_outlined,
};

class _ScanCategoryColors {
  const _ScanCategoryColors(this.container, this.foreground);

  final Color container;
  final Color foreground;
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultNotice extends StatelessWidget {
  const _ResultNotice({
    super.key,
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.tertiaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

class ScanResultRouteErrorPage extends StatelessWidget {
  const ScanResultRouteErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Smart Scan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Data hasil scan tidak tersedia. Mulai pemindaian lagi.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.scan),
                child: const Text('Buka Smart Scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
