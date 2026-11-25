import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/features/rewards/domain/rewards_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RewardsHowToEarnPage extends StatelessWidget {
  const RewardsHowToEarnPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppDimensions.pagePadding),
    children: [
      Text('Cara Dapat Poin', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: AppDimensions.space8),
      Text(
        'Setorkan sampah anorganik bersih dan kering. '
        'Poin dihitung dari berat yang diterima.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppDimensions.space16),
      Card(
        child: Column(
          children: [
            for (final rate in RewardsConfig.pointsPerKgByWasteType.entries)
              ListTile(
                leading: const Icon(Icons.recycling_outlined),
                title: Text(_wasteTypeLabel(rate.key)),
                trailing: Text('${rate.value} poin/kg'),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppDimensions.space16),
      Text('Bonus', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppDimensions.space8),
      const _BonusTile(
        title: 'Penjemputan pertama',
        description: '+20 poin satu kali untuk pesanan pertama yang selesai.',
      ),
      const _BonusTile(
        title: 'Setoran minimal 10 kg',
        description: 'Bonus 10% dari poin dasar pada satu pesanan.',
      ),
      const _BonusTile(
        title: 'Kuis edukasi sempurna',
        description: '+10 poin saat semua jawaban kuis benar.',
      ),
      const SizedBox(height: AppDimensions.space16),
      for (final reason in RewardsConfig.noPointsReasons.entries)
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_wasteTypeLabel(reason.key)),
            subtitle: Text(reason.value),
          ),
        ),
      const SizedBox(height: AppDimensions.space16),
      FilledButton.icon(
        onPressed: () => context.go(AppRoutes.scan),
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Buka Smart Scan'),
      ),
      const SizedBox(height: AppDimensions.space8),
      OutlinedButton.icon(
        onPressed: () => context.go(AppRoutes.pickupNew),
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Jadwalkan Penjemputan'),
      ),
    ],
  );

  String _wasteTypeLabel(String key) => switch (key) {
    'plastic' => 'Plastik',
    'paperCardboard' => 'Kertas / kardus',
    'glass' => 'Kaca',
    'metal' => 'Logam',
    'smallElectronics' => 'Elektronik kecil',
    'organic' => 'Organik',
    'hazardous' => 'B3',
    _ => key,
  };
}

class _BonusTile extends StatelessWidget {
  const _BonusTile({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.stars_outlined),
      title: Text(title),
      subtitle: Text(description),
    ),
  );
}
