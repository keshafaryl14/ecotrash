import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardsVouchersPage extends ConsumerStatefulWidget {
  const RewardsVouchersPage({super.key});

  @override
  ConsumerState<RewardsVouchersPage> createState() =>
      _RewardsVouchersPageState();
}

class _RewardsVouchersPageState extends ConsumerState<RewardsVouchersPage> {
  RewardVoucherStatus _status = RewardVoucherStatus.active;

  @override
  Widget build(BuildContext context) {
    final vouchers = ref.watch(rewardsControllerProvider);
    return vouchers.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat voucher'),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voucher gagal dimuat: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(rewardsControllerProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        final filtered =
            items.where((voucher) => voucher.status == _status).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Voucher Saya',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<RewardVoucherStatus>(
              key: const Key('my-vouchers-status-filter'),
              segments: const [
                ButtonSegment(
                  value: RewardVoucherStatus.active,
                  label: Text('Aktif'),
                ),
                ButtonSegment(
                  value: RewardVoucherStatus.used,
                  label: Text('Terpakai'),
                ),
                ButtonSegment(
                  value: RewardVoucherStatus.expired,
                  label: Text('Kedaluwarsa'),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (selection) =>
                  setState(() => _status = selection.first),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('Belum ada voucher ${_status.label.toLowerCase()}.'),
                  ],
                ),
              )
            else
              for (final voucher in filtered)
                _VoucherCard(
                  voucher: voucher,
                  onMarkUsed: () => _markUsed(voucher),
                ),
          ],
        );
      },
    );
  }

  Future<void> _markUsed(RewardVoucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai voucher terpakai?'),
        content: Text('Voucher ${voucher.code} tidak dapat digunakan lagi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tandai terpakai'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(rewardsControllerProvider.notifier).markUsed(voucher.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher, required this.onMarkUsed});

  final RewardVoucher voucher;
  final VoidCallback onMarkUsed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    voucher.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(voucher.status.label)),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              voucher.code,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Berlaku hingga ${_formatDate(voucher.expiresAt)}'),
            if (voucher.usedAt != null)
              Text('Digunakan pada ${_formatDate(voucher.usedAt!)}'),
            if (voucher.status == RewardVoucherStatus.active) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onMarkUsed,
                  child: const Text('Tandai terpakai'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

extension on RewardVoucherStatus {
  String get label => switch (this) {
    RewardVoucherStatus.active => 'Aktif',
    RewardVoucherStatus.used => 'Terpakai',
    RewardVoucherStatus.expired => 'Kedaluwarsa',
  };
}
