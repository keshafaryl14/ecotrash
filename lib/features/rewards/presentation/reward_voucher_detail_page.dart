import 'package:ecotrash/core/animations/falling_leaves.dart';
import 'package:ecotrash/core/theme/app_dimensions.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/core/widgets/app_state_widgets.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/rewards_config.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_gateway.dart';
import 'package:ecotrash/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';

class RewardVoucherDetailPage extends ConsumerStatefulWidget {
  const RewardVoucherDetailPage({required this.voucherId, super.key});

  final String voucherId;

  @override
  ConsumerState<RewardVoucherDetailPage> createState() =>
      _RewardVoucherDetailPageState();
}

class _RewardVoucherDetailPageState
    extends ConsumerState<RewardVoucherDetailPage> {
  final _receiptController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = ref.watch(earthAnimationsEnabledProvider);
    ref.listen<String?>(rewardsOperationMessageProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next)));
        ref.read(rewardsOperationMessageProvider.notifier).clear();
      }
    });
    final vouchers = ref.watch(voucherListProvider);
    return vouchers.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat voucher'),
      ),
      error: (error, _) => AppMessageState(
        icon: Icons.error_outline,
        message: 'Voucher gagal dimuat: $error',
        actionLabel: 'Coba lagi',
        onAction: () => ref.invalidate(voucherListProvider),
      ),
      data: (items) {
        final matches = items.where((item) => item.id == widget.voucherId);
        if (matches.isEmpty) {
          return const AppMessageState(
            icon: Icons.search_off,
            message: 'Voucher tidak ditemukan.',
          );
        }
        return _buildVoucher(context, matches.first, animationsEnabled);
      },
    );
  }

  Widget _buildVoucher(
    BuildContext context,
    RewardVoucher voucher,
    bool animationsEnabled,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isActive = voucher.status == RewardVoucherStatus.active;
    final isEwallet = voucher.ewalletProvider != null;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pagePadding),
      children: [
        if (voucher.status == RewardVoucherStatus.used)
          FallingLeaves(
            width: 240,
            height: 72,
            count: 8,
            enabled: animationsEnabled,
          ),
        Text(voucher.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.space8),
        Chip(label: Text(_statusLabel(voucher.status))),
        Screenshot(
          controller: _receiptController,
          child: Card(
            color: colors.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                children: [
                  Text(voucher.merchant),
                  const SizedBox(height: AppDimensions.space12),
                  if (isEwallet)
                    _EwalletReceipt(voucher: voucher)
                  else ...[
                    QrImageView(
                      data: voucher.code,
                      size: 210,
                      eyeStyle: QrEyeStyle(
                        color: isActive
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        color: isActive
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                      backgroundColor: colors.surface,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    SelectableText(
                      voucher.code,
                      key: const Key('voucher-code'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space8),
                  Text('Nilai: ${_valueLabel(voucher)}'),
                  Text('Berlaku hingga ${_formatDate(voucher.expiresAt)}'),
                  if (voucher.usedAt != null)
                    Text('Digunakan ${_formatDate(voucher.usedAt!)}'),
                  if (voucher.terms.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space12),
                    Text(voucher.terms, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (isEwallet) ...[
          const SizedBox(height: AppDimensions.space12),
          Text('Tujuan: ${maskIndonesianPhone(voucher.targetPhone!)}'),
          if (voucher.status == RewardVoucherStatus.processing) ...[
            const SizedBox(height: AppDimensions.space8),
            const LinearProgressIndicator(),
            const Text('Top-up sedang diproses (simulasi 3–5 detik).'),
          ],
          if (voucher.status == RewardVoucherStatus.used)
            Text('ID transaksi: ${voucher.payoutTransactionId ?? '-'}'),
        ],
        const SizedBox(height: AppDimensions.space16),
        if (!isEwallet)
          OutlinedButton.icon(
            key: const Key('voucher-copy-code'),
            onPressed: () => _copyCode(voucher.code),
            icon: const Icon(Icons.copy),
            label: const Text('Salin Kode'),
          ),
        if (isActive && !isEwallet) ...[
          FilledButton.icon(
            key: const Key('voucher-use'),
            onPressed: () => _showUseVoucher(voucher),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Gunakan Voucher'),
          ),
          TextButton(
            key: const Key('voucher-mark-used'),
            onPressed: () => _markUsed(voucher),
            child: const Text('Tandai Sudah Digunakan (mode demo)'),
          ),
        ],
        if (isActive &&
            DateTime.now().difference(voucher.createdAt) <=
                RewardsConfig.cancellationWindow)
          TextButton.icon(
            key: const Key('voucher-cancel'),
            onPressed: () => _cancelVoucher(voucher),
            icon: const Icon(Icons.undo),
            label: const Text('Batalkan dan kembalikan poin'),
          ),
        if (voucher.status == RewardVoucherStatus.used && isEwallet)
          FilledButton.icon(
            key: const Key('voucher-share-receipt'),
            onPressed: () => _shareReceipt(voucher),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Bagikan Bukti Transaksi'),
          ),
      ],
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      _message('Kode voucher disalin.');
    }
  }

  Future<void> _showUseVoucher(RewardVoucher voucher) async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tunjukkan ke kasir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: voucher.code, size: 280),
              const SizedBox(height: AppDimensions.space8),
              SelectableText(voucher.code),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _message('QR voucher tidak dapat dibuka: $error');
      }
    } finally {
      try {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      } catch (error) {
        if (mounted) {
          _message('Kecerahan layar tidak dapat dipulihkan: $error');
        }
      }
    }
  }

  Future<void> _markUsed(RewardVoucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Sudah Digunakan?'),
        content: const Text(
          'Mode demo: voucher langsung ditandai terpakai. '
          'Pada produksi, status diverifikasi oleh API merchant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(rewardsControllerProvider.notifier).markUsed(voucher.id);
      if (mounted) {
        _message('Voucher ditandai terpakai.');
      }
    } catch (error) {
      if (mounted) {
        _message('Voucher gagal diperbarui: $error');
      }
    }
  }

  Future<void> _cancelVoucher(RewardVoucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan penukaran?'),
        content: Text(
          'Sebanyak ${voucher.pointsCost} poin akan dikembalikan ke saldo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap simpan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(rewardsControllerProvider.notifier)
          .cancelVoucher(voucher.id);
      if (mounted) {
        _message('Voucher dibatalkan dan poin sudah dikembalikan.');
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString());
      }
    }
  }

  Future<void> _shareReceipt(RewardVoucher voucher) async {
    try {
      final image = await _receiptController.capture();
      if (image == null) {
        throw StateError('Bukti transaksi tidak dapat dibuat sebagai gambar.');
      }
      await SharePlus.instance.share(
        ShareParams(
          title: 'Bukti transaksi EcoTrash',
          text: 'Penukaran ${voucher.title} berhasil.',
          files: [
            XFile.fromData(
              image,
              mimeType: 'image/png',
              name: 'bukti-ecotrash-${voucher.id}.png',
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _message('Bukti transaksi gagal dibagikan: $error');
      }
    }
  }

  String _valueLabel(RewardVoucher voucher) => voucher.ewalletProvider != null
      ? 'Rp${voucher.value}'
      : voucher.value == 1
      ? 'Hadiah produk'
      : '${voucher.value}%';

  String _statusLabel(RewardVoucherStatus status) => switch (status) {
    RewardVoucherStatus.active => 'Aktif',
    RewardVoucherStatus.processing => 'Diproses',
    RewardVoucherStatus.used => 'Terpakai',
    RewardVoucherStatus.expired => 'Kedaluwarsa',
    RewardVoucherStatus.cancelled => 'Dibatalkan',
    RewardVoucherStatus.failed => 'Gagal',
  };

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EwalletReceipt extends StatelessWidget {
  const _EwalletReceipt({required this.voucher});

  final RewardVoucher voucher;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(
        voucher.status == RewardVoucherStatus.used
            ? Icons.check_circle_outline
            : Icons.account_balance_wallet_outlined,
        size: AppDimensions.space32 * 2,
      ),
      const SizedBox(height: AppDimensions.space8),
      Text(
        voucher.status == RewardVoucherStatus.used
            ? 'Top-up berhasil'
            : voucher.status == RewardVoucherStatus.failed
            ? 'Top-up gagal'
            : 'Top-up sedang diproses',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text('${voucher.ewalletProvider} · Rp${voucher.value}'),
      Text(maskIndonesianPhone(voucher.targetPhone ?? '')),
      if (voucher.payoutTransactionId != null)
        Text('ID transaksi: ${voucher.payoutTransactionId}'),
    ],
  );
}
