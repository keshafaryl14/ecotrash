import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardCatalogCard extends ConsumerWidget {
  const RewardCatalogCard({
    required this.reward,
    required this.balance,
    required this.onTap,
    this.onRedeem,
    super.key,
  });

  final Reward reward;
  final int balance;
  final VoidCallback onTap;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(remainingRewardStockProvider(reward));
    final outOfStock = stock.asData?.value == 0;
    final insufficient = balance < reward.pointsCost;
    final unavailable = !reward.active || outOfStock;
    final colors = Theme.of(context).colorScheme;
    final icon = switch (reward.category) {
      RewardCategory.ewallet => Icons.account_balance_wallet_outlined,
      RewardCategory.voucherDiskon ||
      RewardCategory.ecoVoucher => Icons.local_offer_outlined,
      RewardCategory.produkRamahLingkungan => Icons.shopping_bag_outlined,
    };

    return Card(
      key: Key('reward-card-${reward.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      reward.merchant,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Text('${reward.pointsCost} poin'),
                    if (outOfStock)
                      Text(
                        'Stok habis',
                        key: Key('reward-out-of-stock-${reward.id}'),
                        style: TextStyle(color: colors.error),
                      )
                    else if (insufficient)
                      Text(
                        'Poin kurang',
                        key: Key('reward-insufficient-${reward.id}'),
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (onRedeem != null)
                FilledButton.tonal(
                  onPressed: insufficient || unavailable ? null : onRedeem,
                  child: Text(unavailable ? 'Habis' : 'Tukar'),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
