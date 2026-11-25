import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/animations/growing_plant.dart';
import 'package:ecotrash/core/animations/points_burst.dart';
import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(pointsBalanceProvider);
    final lifetime = ref.watch(lifetimePointsProvider);
    final animationsEnabled = ref.watch(earthAnimationsEnabledProvider);
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        Text(
          'Rewards & Poin',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Dampak baikmu bisa ditukar menjadi manfaat nyata.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimensions.space16),
        balance.when(
          loading: () =>
              const AppLoadingSkeleton(label: 'Memuat saldo poin', rows: 1),
          error: (error, _) => AppMessageState(
            icon: Icons.error_outline,
            message: 'Saldo poin gagal dimuat: $error',
            actionLabel: 'Coba lagi',
            onAction: () => ref.invalidate(pointsBalanceProvider),
          ),
          data: (points) => lifetime.when(
            loading: () => _BalanceCard(
              points: points,
              lifetime: points,
              animationsEnabled: animationsEnabled,
            ),
            error: (error, _) => AppMessageState(
              icon: Icons.error_outline,
              message: 'Level gagal dimuat: $error',
              actionLabel: 'Coba lagi',
              onAction: () => ref.invalidate(lifetimePointsProvider),
            ),
            data: (total) => PointsBurst(
              points: points,
              enabled: animationsEnabled,
              child: _BalanceCard(
                points: points,
                lifetime: total,
                animationsEnabled: animationsEnabled,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        Wrap(
          spacing: AppDimensions.space8,
          runSpacing: AppDimensions.space8,
          children: [
            _QuickAction(
              key: const Key('rewards-my-vouchers'),
              label: 'Voucher Saya',
              icon: Icons.confirmation_number_outlined,
              onTap: () => context.push(AppRoutes.rewardVouchers),
            ),
            _QuickAction(
              key: const Key('rewards-history'),
              label: 'Riwayat Poin',
              icon: Icons.history,
              onTap: () => context.push(AppRoutes.rewardHistory),
            ),
            _QuickAction(
              key: const Key('rewards-how-to-earn'),
              label: 'Cara Dapat Poin',
              icon: Icons.info_outline,
              onTap: () => context.push(AppRoutes.rewardsHowToEarn),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Reward Pilihan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              key: const Key('rewards-open-catalog'),
              onPressed: () => context.push(AppRoutes.rewardCatalog),
              child: const Text('Lihat katalog'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space8),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Reward.catalog.take(4).length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimensions.space12),
            itemBuilder: (context, index) {
              final reward = Reward.catalog[index];
              return SizedBox(
                width: 230,
                child: Card(
                  color: colors.secondaryContainer,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.cardRadius,
                    ),
                    onTap: () => context.push(
                      AppRoutes.rewardDetail.replaceFirst(':id', reward.id),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            reward.category == RewardCategory.ewallet
                                ? Icons.account_balance_wallet_outlined
                                : Icons.eco_outlined,
                            color: colors.onSecondaryContainer,
                          ),
                          const Spacer(),
                          Text(
                            reward.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('${reward.pointsCost} poin'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        FilledButton.icon(
          key: const Key('rewards-open-catalog-button'),
          onPressed: () => context.push(AppRoutes.rewardCatalog),
          icon: const Icon(Icons.card_giftcard_outlined),
          label: const Text('Jelajahi semua reward'),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.points,
    required this.lifetime,
    required this.animationsEnabled,
  });

  final int points;
  final int lifetime;
  final bool animationsEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final level = RewardLevel.forTotalPoints(lifetime);
    final nextLevelPoints = level.pointsToNextLevel(lifetime);
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        'Saldo poin',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: points),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) => Text(
                      '$value poin',
                      key: const Key('rewards-points-balance'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    children: [
                      Text('${level.badge} ${level.name}'),
                      const Spacer(),
                      Text('$lifetime total poin'),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  LinearProgressIndicator(
                    key: const Key('rewards-level-progress'),
                    value: level.progressFor(lifetime),
                    minHeight: AppDimensions.space8,
                    borderRadius: BorderRadius.circular(AppDimensions.space8),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    nextLevelPoints == null
                        ? 'Level tertinggi telah tercapai!'
                        : '$nextLevelPoints poin lagi menuju '
                              '${RewardLevel.levels[RewardLevel.levels.indexOf(level) + 1].name}',
                    key: const Key('rewards-level-next'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            GrowingPlant(
              progress: level.progressFor(lifetime),
              stage: RewardLevel.levels.indexOf(level),
              size: 96,
              enabled: animationsEnabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: AppDimensions.space16),
    label: Text(label),
    onPressed: onTap,
  );
}
