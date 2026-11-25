import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_gateway.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RewardDetailPage extends ConsumerWidget {
  const RewardDetailPage({required this.rewardId, super.key});

  final String rewardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = Reward.catalog
        .where((item) => item.id == rewardId)
        .firstOrNull;
    if (reward == null) {
      return const AppMessageState(
        icon: Icons.search_off,
        message: 'Reward tidak ditemukan.',
      );
    }
    final balance = ref.watch(pointsBalanceProvider);
    final stock = ref.watch(remainingRewardStockProvider(reward));
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        Text(reward.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.space8),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              children: [
                Icon(
                  reward.category == RewardCategory.ewallet
                      ? Icons.account_balance_wallet_outlined
                      : Icons.eco_outlined,
                  size: AppDimensions.space32 * 2,
                ),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  reward.category.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        Text(reward.description),
        const SizedBox(height: AppDimensions.space16),
        _RewardDetailRow(label: 'Mitra', value: reward.merchant),
        _RewardDetailRow(
          label: 'Nilai reward',
          value: reward.category == RewardCategory.ewallet
              ? 'Rp${(reward.amountRupiah ?? reward.value).toString()}'
              : reward.category == RewardCategory.voucherDiskon
              ? '${reward.value}%'
              : reward.title,
        ),
        _RewardDetailRow(
          label: 'Biaya penukaran',
          value: '${reward.pointsCost} poin',
        ),
        _RewardDetailRow(
          label: 'Masa berlaku',
          value: '${reward.validityDays} hari setelah ditukar',
        ),
        _RewardDetailRow(label: 'Syarat dan ketentuan', value: reward.terms),
        if (reward.stock != null)
          stock.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Stok gagal dimuat: $error'),
            data: (value) => _RewardDetailRow(
              label: 'Stok tersedia',
              value: '${value ?? 0}',
            ),
          ),
        const SizedBox(height: AppDimensions.space16),
        balance.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppMessageState(
            icon: Icons.error_outline,
            message: 'Saldo poin gagal dimuat: $error',
            actionLabel: 'Coba lagi',
            onAction: () => ref.invalidate(pointsBalanceProvider),
          ),
          data: (points) => FilledButton(
            key: const Key('reward-redeem-now'),
            onPressed:
                !reward.active ||
                    points < reward.pointsCost ||
                    stock.asData?.value == 0
                ? null
                : () => _openConfirmation(context, ref, reward, points),
            child: Text(
              points < reward.pointsCost
                  ? 'Poin belum cukup'
                  : stock.asData?.value == 0
                  ? 'Stok habis'
                  : 'Tukar Sekarang',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openConfirmation(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
    int balance,
  ) async {
    final lastPhone = reward.category == RewardCategory.ewallet
        ? await ref.read(rewardsControllerProvider.notifier).lastEwalletPhone()
        : null;
    if (!context.mounted) {
      return;
    }
    final voucher = await showModalBottomSheet<RewardVoucher>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _RedemptionConfirmationSheet(
        reward: reward,
        balance: balance,
        initialPhone: lastPhone,
      ),
    );
    if (voucher == null || !context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('reward-redemption-success'),
        icon: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 350),
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Icon(
            Icons.check_circle,
            color: Theme.of(dialogContext).colorScheme.primary,
            size: AppDimensions.space32 * 2,
          ),
        ),
        title: const Text('Reward berhasil ditukar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              voucher.status == RewardVoucherStatus.processing
                  ? 'Top-up e-wallet sedang diproses.'
                  : voucher.title,
            ),
            const SizedBox(height: AppDimensions.space8),
            SelectableText(voucher.code),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push(
                AppRoutes.rewardVoucherDetail.replaceFirst(':id', voucher.id),
              );
            },
            child: const Text('Lihat Voucher'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(AppRoutes.rewardCatalog);
            },
            child: const Text('Kembali ke Katalog'),
          ),
        ],
      ),
    );
  }
}

class _RedemptionConfirmationSheet extends ConsumerStatefulWidget {
  const _RedemptionConfirmationSheet({
    required this.reward,
    required this.balance,
    this.initialPhone,
  });

  final Reward reward;
  final int balance;
  final String? initialPhone;

  @override
  ConsumerState<_RedemptionConfirmationSheet> createState() =>
      _RedemptionConfirmationSheetState();
}

class _RedemptionConfirmationSheetState
    extends ConsumerState<_RedemptionConfirmationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.initialPhone ?? '',
  );
  String? _provider = supportedEwalletProviders.first;
  bool _isSubmitting = false;

  bool get _requiresEwallet => widget.reward.category == RewardCategory.ewallet;

  @override
  Widget build(BuildContext context) {
    final after = widget.balance - widget.reward.pointsCost;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding,
        AppDimensions.space16,
        AppDimensions.pagePadding,
        MediaQuery.viewInsetsOf(context).bottom + AppDimensions.space16,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Konfirmasi Penukaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.space12),
            Text(widget.reward.title),
            Text('Biaya: ${widget.reward.pointsCost} poin'),
            Text('Saldo sebelum: ${widget.balance} poin'),
            Text('Saldo sesudah: $after poin'),
            if (_requiresEwallet) ...[
              const SizedBox(height: AppDimensions.space16),
              DropdownButtonFormField<String>(
                key: const Key('ewallet-provider'),
                initialValue: _provider,
                decoration: const InputDecoration(
                  labelText: 'Pilih e-wallet',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final provider in supportedEwalletProviders)
                    DropdownMenuItem(value: provider, child: Text(provider)),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _provider = value),
              ),
              const SizedBox(height: AppDimensions.space12),
              TextFormField(
                key: const Key('ewallet-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor ponsel e-wallet',
                  hintText: '081234567890 atau +6281234567890',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value != null && isValidIndonesianPhone(value)
                    ? null
                    : 'Masukkan nomor ponsel Indonesia yang valid.',
              ),
            ],
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: FilledButton(
                    key: const Key('reward-confirm-redemption'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Konfirmasi Tukar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_requiresEwallet && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final voucher = await ref
          .read(rewardsControllerProvider.notifier)
          .redeem(
            widget.reward,
            ewalletProvider: _requiresEwallet ? _provider : null,
            targetPhone: _requiresEwallet ? _phoneController.text.trim() : null,
          );
      if (mounted) {
        Navigator.pop(context, voucher);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}

class _RewardDetailRow extends StatelessWidget {
  const _RewardDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
