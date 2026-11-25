import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    ref.listen<String?>(rewardsOperationMessageProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
        ref.read(rewardsOperationMessageProvider.notifier).clear();
      }
    });
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
        final filtered = items.where((voucher) {
          if (_status == RewardVoucherStatus.active) {
            return voucher.status == RewardVoucherStatus.active ||
                voucher.status == RewardVoucherStatus.processing;
          }
          if (_status == RewardVoucherStatus.expired) {
            return voucher.status == RewardVoucherStatus.expired ||
                voucher.status == RewardVoucherStatus.failed ||
                voucher.status == RewardVoucherStatus.cancelled;
          }
          return voucher.status == _status;
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ListView(
          padding: const EdgeInsets.all(AppDimensions.pagePadding),
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
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.space32,
                ),
                child: AppMessageState(
                  icon: Icons.confirmation_number_outlined,
                  message: 'Belum ada voucher ${_status.label.toLowerCase()}.',
                  actionLabel: _status == RewardVoucherStatus.active
                      ? 'Cari reward'
                      : null,
                  onAction: _status == RewardVoucherStatus.active
                      ? () => context.push(AppRoutes.rewardCatalog)
                      : null,
                ),
              )
            else
              for (final voucher in filtered)
                _VoucherCard(
                  voucher: voucher,
                  onTap: () => context.push(
                    AppRoutes.rewardVoucherDetail.replaceFirst(
                      ':id',
                      voucher.id,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher, required this.onTap});

  final RewardVoucher voucher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.confirmation_number_outlined),
        title: Text(voucher.title),
        subtitle: Text(
          '${voucher.code}\n${voucher.merchant} · Berlaku hingga ${_formatDate(voucher.expiresAt)}'
          '${voucher.status == RewardVoucherStatus.active ? '\n${_remainingDays(voucher.expiresAt)}' : ''}',
        ),
        isThreeLine: true,
        trailing: Chip(label: Text(voucher.status.label)),
      ),
    );
  }

  String _remainingDays(DateTime expiry) {
    final days = expiry.difference(DateTime.now()).inDays;
    return days <= 0 ? 'Hari ini' : '$days hari lagi';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

extension on RewardVoucherStatus {
  String get label => switch (this) {
    RewardVoucherStatus.active => 'Aktif',
    RewardVoucherStatus.processing => 'Diproses',
    RewardVoucherStatus.used => 'Terpakai',
    RewardVoucherStatus.expired => 'Kedaluwarsa',
    RewardVoucherStatus.cancelled => 'Dibatalkan',
    RewardVoucherStatus.failed => 'Gagal',
  };
}
