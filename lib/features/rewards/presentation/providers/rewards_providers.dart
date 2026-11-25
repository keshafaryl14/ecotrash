import 'dart:async';
import 'dart:math';

import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/features/rewards/data/repositories/shared_preferences_reward_repository.dart';
import 'package:ecotrash/features/rewards/data/services/local_rewards_notification_service.dart';
import 'package:ecotrash/features/rewards/data/services/mock_ewallet_payout_gateway.dart';
import 'package:ecotrash/features/rewards/data/services/mock_ewallet_payout_service.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/repositories/reward_repository.dart';
import 'package:ecotrash/features/rewards/domain/rewards_config.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_gateway.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_service.dart';
import 'package:ecotrash/features/rewards/domain/services/rewards_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return SharedPreferencesRewardRepository();
});

final ewalletPayoutServiceProvider = Provider<EwalletPayoutService>((ref) {
  return MockEwalletPayoutService();
});

final ewalletPayoutGatewayProvider = Provider<EwalletPayoutGateway>((ref) {
  return MockEwalletPayoutGateway(ref.watch(ewalletPayoutServiceProvider));
});

final rewardsNotificationServiceProvider = Provider<RewardsNotificationService>(
  (ref) {
    return LocalRewardsNotificationService();
  },
);

final ewalletPayoutDelayProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 4);
});

final rewardsOperationMessageProvider =
    NotifierProvider<RewardsOperationMessageController, String?>(
      RewardsOperationMessageController.new,
    );

class RewardsOperationMessageController extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

final rewardsControllerProvider =
    AsyncNotifierProvider<RewardsController, List<RewardVoucher>>(
      RewardsController.new,
    );

final voucherListProvider = rewardsControllerProvider;

final pointsHistoryProvider = FutureProvider<List<PointsTransaction>>((ref) {
  return ref.watch(pointsServiceProvider).getTransactions();
});

final rewardCatalogProvider =
    FutureProvider.family<List<Reward>, RewardCatalogFilter>((ref, filter) {
      final query = filter.query.trim().toLowerCase();
      final rewards = Reward.catalog.where((reward) {
        final categoryMatches =
            filter.category == null ||
            reward.category == filter.category ||
            (filter.category == RewardCategory.voucherDiskon &&
                reward.category == RewardCategory.ecoVoucher);
        final queryMatches =
            query.isEmpty ||
            reward.title.toLowerCase().contains(query) ||
            reward.merchant.toLowerCase().contains(query);
        return categoryMatches && queryMatches;
      }).toList();
      switch (filter.sort) {
        case RewardSort.lowestPoints:
          rewards.sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
        case RewardSort.highestPoints:
          rewards.sort((a, b) => b.pointsCost.compareTo(a.pointsCost));
        case RewardSort.popular:
          rewards.sort((a, b) => b.popularity.compareTo(a.popularity));
      }
      return rewards;
    });

final filteredPointsHistoryProvider =
    FutureProvider.family<List<PointsTransaction>, PointsHistoryFilter>((
      ref,
      filter,
    ) {
      return ref
          .watch(pointsServiceProvider)
          .getHistory(month: filter.month, source: filter.source);
    });

final remainingRewardStockProvider = FutureProvider.family<int?, Reward>((
  ref,
  reward,
) {
  return ref.watch(rewardRepositoryProvider).getRemainingStock(reward);
});

enum RewardSort { lowestPoints, highestPoints, popular }

class RewardCatalogFilter {
  const RewardCatalogFilter({
    this.category,
    this.query = '',
    this.sort = RewardSort.popular,
  });

  final RewardCategory? category;
  final String query;
  final RewardSort sort;

  @override
  bool operator ==(Object other) =>
      other is RewardCatalogFilter &&
      other.category == category &&
      other.query == query &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(category, query, sort);
}

class PointsHistoryFilter {
  const PointsHistoryFilter({this.month, this.source});

  final DateTime? month;
  final PointsSource? source;

  @override
  bool operator ==(Object other) =>
      other is PointsHistoryFilter &&
      other.month?.year == month?.year &&
      other.month?.month == month?.month &&
      other.source == source;

  @override
  int get hashCode => Object.hash(month?.year, month?.month, source);
}

class RewardsController extends AsyncNotifier<List<RewardVoucher>> {
  bool _isRedeeming = false;
  final Set<String> _activeEwalletRewardIds = {};

  bool get isRedeeming => _isRedeeming || _activeEwalletRewardIds.isNotEmpty;

  @override
  Future<List<RewardVoucher>> build() async {
    final vouchers = await ref.read(rewardRepositoryProvider).getVouchers();
    return [...vouchers]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<int?> remainingStock(Reward reward) =>
      ref.read(rewardRepositoryProvider).getRemainingStock(reward);

  Future<String?> lastEwalletPhone() =>
      ref.read(rewardRepositoryProvider).getLastEwalletPhone();

  Future<RewardVoucher> redeem(
    Reward reward, {
    String? ewalletProvider,
    String? targetPhone,
    String? idempotencyKey,
  }) async {
    if (_isRedeeming || _activeEwalletRewardIds.contains(reward.id)) {
      throw const RewardRedemptionException(
        'Penukaran sedang diproses. Tunggu hingga selesai.',
      );
    }
    _isRedeeming = true;
    final repository = ref.read(rewardRepositoryProvider);
    final points = ref.read(pointsServiceProvider);
    final redemptionId =
        idempotencyKey ?? DateTime.now().microsecondsSinceEpoch.toString();
    var pointsDeducted = false;
    var voucherSaved = false;
    var payoutStarted = false;
    try {
      if (!reward.active) {
        throw const RewardRedemptionException('Reward ini sudah tidak aktif.');
      }
      final existing = await repository.getVoucher(redemptionId);
      if (existing != null) {
        if (existing.rewardId != reward.id ||
            existing.pointsCost != reward.pointsCost) {
          throw const RewardRedemptionException(
            'Kunci penukaran ini sudah digunakan untuk transaksi lain.',
          );
        }
        return existing;
      }
      if (await repository.getRedemptionsOn(DateTime.now()) >=
          RewardsConfig.maxRedemptionsPerDay) {
        throw const RewardRedemptionException(
          'Batas penukaran 3 reward per hari sudah tercapai.',
        );
      }
      final stock = await repository.getRemainingStock(reward);
      if (stock != null && stock <= 0) {
        throw const RewardRedemptionException('Stok reward ini sudah habis.');
      }
      if (reward.category == RewardCategory.ewallet) {
        if (ewalletProvider == null ||
            !supportedEwalletProviders.contains(ewalletProvider)) {
          throw const RewardRedemptionException(
            'Pilih penyedia e-wallet yang tersedia.',
          );
        }
        if (targetPhone == null || !isValidIndonesianPhone(targetPhone)) {
          throw const RewardRedemptionException(
            'Masukkan nomor ponsel Indonesia yang valid, misalnya 081234567890.',
          );
        }
      }
      final result = await points.spendPoints(
        points: reward.pointsCost,
        description: reward.title,
        referenceId: 'reward:$redemptionId',
      );
      if (result case ResultFailure<PointsTransaction>(:final error)) {
        if (error is InsufficientPointsException) {
          throw const RewardInsufficientPointsException();
        }
        throw RewardRedemptionException(error.message);
      }
      pointsDeducted = true;

      if (reward.category == RewardCategory.ewallet) {
        await repository.saveLastEwalletPhone(targetPhone!);
        _activeEwalletRewardIds.add(reward.id);
      }
      final now = DateTime.now();
      final voucher = RewardVoucher(
        id: redemptionId,
        rewardId: reward.id,
        title: reward.title,
        code: _createVoucherCode(),
        createdAt: now,
        expiresAt: now.add(Duration(days: reward.validityDays)),
        statusOverride: reward.category == RewardCategory.ewallet
            ? RewardVoucherStatus.processing
            : null,
        value: reward.value,
        merchant: reward.merchant,
        terms: reward.terms,
        targetPhone: targetPhone,
        ewalletProvider: ewalletProvider,
        payoutStatus: reward.category == RewardCategory.ewallet
            ? EwalletPayoutStatus.processing
            : EwalletPayoutStatus.notApplicable,
        redemptionReference: redemptionId,
        pointsCost: reward.pointsCost,
      );
      await repository.saveVoucher(voucher);
      voucherSaved = true;
      _invalidatePoints();
      if (reward.category == RewardCategory.ewallet) {
        unawaited(_processEwalletPayout(voucher, reward));
        payoutStarted = true;
      }
      try {
        await _reloadVouchers();
      } catch (error) {
        ref
            .read(rewardsOperationMessageProvider.notifier)
            .show(
              'Voucher tersimpan, tetapi daftar belum dapat diperbarui: $error',
            );
      }
      if (reward.category != RewardCategory.ewallet) {
        await _notifyVoucherCreated(voucher);
      }
      return voucher;
    } catch (error) {
      if (pointsDeducted && !voucherSaved) {
        try {
          await points.refundPoints(
            points: reward.pointsCost,
            description: 'Pengembalian poin untuk ${reward.title}',
            referenceId: 'refund:$redemptionId',
          );
          _invalidatePoints();
        } catch (refundError) {
          throw RewardRedemptionException(
            'Penukaran gagal ($error) dan pengembalian poin gagal '
            '($refundError). Hubungi dukungan EcoTrash.',
          );
        }
      }
      if (error is RewardRedemptionException) {
        rethrow;
      }
      throw RewardRedemptionException('Reward gagal ditukar: $error');
    } finally {
      _isRedeeming = false;
      if (!payoutStarted) {
        _activeEwalletRewardIds.remove(reward.id);
      }
    }
  }

  Future<void> _processEwalletPayout(
    RewardVoucher voucher,
    Reward reward,
  ) async {
    late final String transactionId;
    try {
      transactionId = await ref
          .read(ewalletPayoutGatewayProvider)
          .transfer(
            redemptionId: voucher.id,
            provider: voucher.ewalletProvider!,
            phoneNumber: voucher.targetPhone!,
            amountRupiah: reward.amountRupiah ?? reward.value,
          );
      await Future<void>.delayed(ref.read(ewalletPayoutDelayProvider));
    } catch (error) {
      try {
        await ref
            .read(pointsServiceProvider)
            .refundPoints(
              points: voucher.pointsCost,
              description: 'Pengembalian poin karena top-up e-wallet gagal',
              referenceId: 'payout-refund:${voucher.id}',
            );
        await ref
            .read(rewardRepositoryProvider)
            .updateVoucher(
              voucher.copyWith(
                statusOverride: RewardVoucherStatus.failed,
                payoutStatus: EwalletPayoutStatus.failed,
              ),
            );
        _invalidatePoints();
        await _reloadVouchers();
      } catch (refundError) {
        ref
            .read(rewardsOperationMessageProvider.notifier)
            .show(
              'Top-up gagal ($error) dan pengembalian poin gagal '
              '($refundError). Hubungi dukungan EcoTrash.',
            );
        _activeEwalletRewardIds.remove(reward.id);
        return;
      }
      ref
          .read(rewardsOperationMessageProvider.notifier)
          .show('Top-up e-wallet gagal; poin sudah dikembalikan: $error');
      _activeEwalletRewardIds.remove(reward.id);
      return;
    }
    final updated = voucher.copyWith(
      usedAt: DateTime.now(),
      statusOverride: RewardVoucherStatus.used,
      payoutStatus: EwalletPayoutStatus.successful,
      payoutTransactionId: transactionId,
    );
    try {
      await ref.read(rewardRepositoryProvider).updateVoucher(updated);
      await _reloadVouchers();
      await _notifyVoucherCreated(updated);
    } catch (error) {
      ref
          .read(rewardsOperationMessageProvider.notifier)
          .show(
            'Top-up berhasil, tetapi status voucher atau notifikasi gagal diperbarui: $error',
          );
    } finally {
      _activeEwalletRewardIds.remove(reward.id);
    }
  }

  Future<void> _notifyVoucherCreated(RewardVoucher voucher) async {
    try {
      final notifications = ref.read(rewardsNotificationServiceProvider);
      if (!await notifications.requestPermission()) {
        ref
            .read(rewardsOperationMessageProvider.notifier)
            .show(
              'Reward tersimpan. Aktifkan izin notifikasi untuk pengingat masa berlaku.',
            );
        return;
      }
      await notifications.redemptionSucceeded(voucher);
      await notifications.scheduleExpiryReminder(voucher);
    } catch (error) {
      ref
          .read(rewardsOperationMessageProvider.notifier)
          .show('Voucher tersimpan, tetapi notifikasi gagal disiapkan: $error');
    }
  }

  Future<void> markUsed(String voucherId) async {
    await ref.read(rewardRepositoryProvider).markVoucherUsed(voucherId);
    await _reloadVouchers();
  }

  Future<void> cancelVoucher(String voucherId) async {
    final repository = ref.read(rewardRepositoryProvider);
    final voucher = await repository.getVoucher(voucherId);
    if (voucher == null) {
      throw const RewardRedemptionException('Voucher tidak ditemukan.');
    }
    if (voucher.status != RewardVoucherStatus.active) {
      throw const RewardRedemptionException(
        'Voucher ini tidak dapat dibatalkan.',
      );
    }
    if (DateTime.now().difference(voucher.createdAt) >
        RewardsConfig.cancellationWindow) {
      throw const RewardRedemptionException(
        'Pembatalan hanya dapat dilakukan dalam 24 jam setelah penukaran.',
      );
    }
    await ref
        .read(pointsServiceProvider)
        .refundPoints(
          points: voucher.pointsCost,
          description: 'Pengembalian poin karena voucher dibatalkan',
          referenceId: 'cancel-refund:$voucherId',
        );
    await repository.updateVoucher(
      voucher.copyWith(
        statusOverride: RewardVoucherStatus.cancelled,
        cancelledAt: DateTime.now(),
      ),
    );
    _invalidatePoints();
    await _reloadVouchers();
  }

  Future<void> refresh() => _reloadVouchers();

  Future<void> _reloadVouchers() async {
    final vouchers = await ref.read(rewardRepositoryProvider).getVouchers();
    state = AsyncData(
      [...vouchers]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  void _invalidatePoints() {
    ref
      ..invalidate(pointsBalanceProvider)
      ..invalidate(lifetimePointsProvider)
      ..invalidate(pointsTransactionsProvider)
      ..invalidate(pointsHistoryProvider);
  }

  String _createVoucherCode() {
    final random = Random.secure();
    final first = random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    final second = random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    return 'ECO-${first.toUpperCase()}-${second.toUpperCase()}';
  }
}

class RewardRedemptionException implements Exception {
  const RewardRedemptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RewardInsufficientPointsException extends RewardRedemptionException {
  const RewardInsufficientPointsException()
    : super('Poin kamu belum cukup untuk menukar reward ini.');
}
