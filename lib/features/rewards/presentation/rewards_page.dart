import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward_level.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RewardsPage extends ConsumerStatefulWidget {
  const RewardsPage({super.key});

  @override
  ConsumerState<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends ConsumerState<RewardsPage> {
  RewardCategory _category = RewardCategory.ewallet;
  String _selectedMonth = 'all';

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(pointsBalanceProvider);
    final lifetime = ref.watch(lifetimePointsProvider);
    final transactions = ref.watch(pointsHistoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rewards & Poin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            OutlinedButton.icon(
              key: const Key('rewards-my-vouchers'),
              onPressed: () => context.push(AppRoutes.rewardVouchers),
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('Voucher Saya'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        balance.when(
          loading: () => const Card(
            child: SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => _LoadError(
            message: 'Saldo gagal dimuat: $error',
            onRetry: () => ref.invalidate(pointsBalanceProvider),
          ),
          data: (points) => _BalanceCard(
            points: points,
            lifetime: lifetime.asData?.value ?? points,
          ),
        ),
        const SizedBox(height: 24),
        Text('Katalog reward', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SegmentedButton<RewardCategory>(
          key: const Key('rewards-category-filter'),
          segments: const [
            ButtonSegment(
              value: RewardCategory.ewallet,
              label: Text('Saldo e-wallet'),
              icon: Icon(Icons.account_balance_wallet_outlined),
            ),
            ButtonSegment(
              value: RewardCategory.ecoVoucher,
              label: Text('Voucher eco'),
              icon: Icon(Icons.local_offer_outlined),
            ),
          ],
          selected: {_category},
          onSelectionChanged: (selection) =>
              setState(() => _category = selection.first),
        ),
        const SizedBox(height: 12),
        for (final reward in Reward.catalog.where(
          (item) => item.category == _category,
        ))
          _RewardCard(
            reward: reward,
            onRedeem: () => _confirmRedemption(reward),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Riwayat poin',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (transactions.hasValue)
              DropdownButton<String>(
                key: const Key('points-history-month-filter'),
                value: _selectedMonth,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Semua bulan'),
                  ),
                  ..._availableMonths(transactions.value!),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMonth = value);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        transactions.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _LoadError(
            message: 'Riwayat gagal dimuat: $error',
            onRetry: () => ref.invalidate(pointsHistoryProvider),
          ),
          data: (items) => _PointsHistory(transactions: _filterMonth(items)),
        ),
        const SizedBox(height: 24),
        Text(
          'Penukaran e-wallet saat ini berupa kode demo. Saldo belum dikirim '
          'ke penyedia pembayaran.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _availableMonths(
    List<PointsTransaction> transactions,
  ) {
    final months =
        transactions
            .map((transaction) => _monthKey(transaction.createdAt))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (_selectedMonth != 'all' && !months.contains(_selectedMonth)) {
      _selectedMonth = 'all';
    }
    return [
      for (final month in months)
        DropdownMenuItem(value: month, child: Text(_monthLabel(month))),
    ];
  }

  List<PointsTransaction> _filterMonth(List<PointsTransaction> transactions) {
    if (_selectedMonth == 'all') {
      return transactions;
    }
    return transactions
        .where(
          (transaction) => _monthKey(transaction.createdAt) == _selectedMonth,
        )
        .toList();
  }

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(String key) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final parts = key.split('-');
    final month = int.parse(parts[1]);
    return '${monthNames[month - 1]} ${parts[0]}';
  }

  Future<void> _confirmRedemption(Reward reward) async {
    try {
      final balance = await ref.read(pointsBalanceProvider.future);
      if (!mounted) {
        return;
      }
      if (balance < reward.pointsCost) {
        _showMessage('Poin kamu belum cukup untuk menukar reward ini.');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi penukaran'),
          content: Text(
            'Tukar ${reward.pointsCost} poin dengan ${reward.title}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: const Key('reward-confirm-redemption'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tukar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }

      final voucher = await ref
          .read(rewardsControllerProvider.notifier)
          .redeem(reward);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('reward-redemption-success'),
          icon: const Icon(Icons.check_circle_outline),
          title: const Text('Reward berhasil ditukar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(voucher.title),
              const SizedBox(height: 12),
              SelectableText(
                voucher.code,
                key: const Key('reward-voucher-code'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/rewards/vouchers');
              },
              child: const Text('Voucher Saya'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.points, required this.lifetime});

  final int points;
  final int lifetime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = RewardLevel.forTotalPoints(lifetime);
    final nextLevelPoints = level.pointsToNextLevel(lifetime);

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco_outlined, color: colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Saldo poin',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$points poin',
              key: const Key('rewards-points-balance'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Level ${level.name}',
                    key: const Key('rewards-level-name'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('$lifetime total poin'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              key: const Key('rewards-level-progress'),
              value: level.progressFor(lifetime),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text(
              nextLevelPoints == null
                  ? 'Level tertinggi telah tercapai!'
                  : '$nextLevelPoints poin lagi ke level berikutnya',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends ConsumerWidget {
  const _RewardCard({required this.reward, required this.onRedeem});

  final Reward reward;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRedeeming = ref
        .watch(rewardsControllerProvider.notifier)
        .isRedeeming;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            reward.category == RewardCategory.ewallet
                ? Icons.account_balance_wallet_outlined
                : Icons.local_offer_outlined,
          ),
        ),
        title: Text(reward.title),
        subtitle: Text('${reward.pointsCost} poin · ${reward.description}'),
        isThreeLine: true,
        trailing: FilledButton(
          key: Key('redeem-${reward.id}'),
          onPressed: isRedeeming ? null : onRedeem,
          child: const Text('Tukar'),
        ),
      ),
    );
  }
}

class _PointsHistory extends StatelessWidget {
  const _PointsHistory({required this.transactions});

  final List<PointsTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('Belum ada transaksi pada periode ini.')),
      );
    }
    return Column(
      children: [
        for (final transaction in transactions)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  transaction.direction == PointsTransactionDirection.earned
                      ? Icons.add
                      : Icons.remove,
                ),
              ),
              title: Text(transaction.description),
              subtitle: Text(
                '${transaction.source.label} · '
                '${transaction.createdAt.day.toString().padLeft(2, '0')}/'
                '${transaction.createdAt.month.toString().padLeft(2, '0')}/'
                '${transaction.createdAt.year}',
              ),
              trailing: Text(
                '${transaction.direction == PointsTransactionDirection.earned ? '+' : '-'}'
                '${transaction.points}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline),
      title: Text(message),
      trailing: IconButton(
        tooltip: 'Coba lagi',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
      ),
    ),
  );
}
