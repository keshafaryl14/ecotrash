import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/features/rewards/data/repositories/shared_preferences_reward_repository.dart';
import 'package:ecotrash/features/rewards/data/services/mock_ewallet_payout_service.dart';
import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/repositories/reward_repository.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return SharedPreferencesRewardRepository();
});

final ewalletPayoutServiceProvider = Provider<EwalletPayoutService>((ref) {
  return MockEwalletPayoutService();
});

final rewardsControllerProvider =
    AsyncNotifierProvider<RewardsController, List<RewardVoucher>>(
      RewardsController.new,
    );

final pointsHistoryProvider = FutureProvider<List<PointsTransaction>>((ref) {
  return ref.watch(pointsServiceProvider).getTransactions();
});

class RewardsController extends AsyncNotifier<List<RewardVoucher>> {
  bool _isRedeeming = false;

  bool get isRedeeming => _isRedeeming;

  @override
  Future<List<RewardVoucher>> build() {
    return ref.read(rewardRepositoryProvider).getVouchers();
  }

  Future<RewardVoucher> redeem(Reward reward) async {
    if (_isRedeeming) {
      throw const RewardRedemptionException(
        'Penukaran sedang diproses. Tunggu hingga selesai.',
      );
    }
    _isRedeeming = true;
    final points = ref.read(pointsServiceProvider);
    final redemptionId = DateTime.now().microsecondsSinceEpoch.toString();
    var pointsDeducted = false;
    try {
      final balance = await points.getBalance();
      if (balance < reward.pointsCost) {
        throw const RewardInsufficientPointsException();
      }

      await points.redeemPoints(
        points: reward.pointsCost,
        description: reward.title,
        referenceId: 'reward:$redemptionId',
      );
      pointsDeducted = true;

      final code = reward.category == RewardCategory.ewallet
          ? await ref
                .read(ewalletPayoutServiceProvider)
                .createPayoutCode(
                  redemptionId: redemptionId,
                  amountRupiah: reward.amountRupiah!,
                )
          : _createVoucherCode(redemptionId);
      final now = DateTime.now();
      final voucher = RewardVoucher(
        id: redemptionId,
        rewardId: reward.id,
        title: reward.title,
        code: code,
        createdAt: now,
        expiresAt: now.add(Duration(days: reward.validityDays)),
      );
      await ref.read(rewardRepositoryProvider).saveVoucher(voucher);
      state = AsyncData(await ref.read(rewardRepositoryProvider).getVouchers());
      ref
        ..invalidate(pointsBalanceProvider)
        ..invalidate(lifetimePointsProvider)
        ..invalidate(pointsTransactionsProvider)
        ..invalidate(pointsHistoryProvider);
      return voucher;
    } on InsufficientPointsException {
      throw const RewardInsufficientPointsException();
    } catch (error) {
      if (pointsDeducted) {
        try {
          await points.addPoints(
            points: reward.pointsCost,
            source: PointsSource.systemAdjustment,
            description: 'Pengembalian poin untuk ${reward.title}',
            referenceId: 'refund:$redemptionId',
          );
          ref
            ..invalidate(pointsBalanceProvider)
            ..invalidate(lifetimePointsProvider)
            ..invalidate(pointsTransactionsProvider)
            ..invalidate(pointsHistoryProvider);
        } catch (refundError) {
          throw RewardRedemptionException(
            'Penukaran gagal ($error) dan pengembalian poin gagal '
            '($refundError). Hubungi dukungan EcoTrash.',
          );
        }
      }
      if (error is RewardRedemptionException ||
          error is RewardInsufficientPointsException) {
        rethrow;
      }
      throw RewardRedemptionException('Reward gagal ditukar: $error');
    } finally {
      _isRedeeming = false;
    }
  }

  Future<void> markUsed(String voucherId) async {
    await ref.read(rewardRepositoryProvider).markVoucherUsed(voucherId);
    state = AsyncData(await ref.read(rewardRepositoryProvider).getVouchers());
  }

  String _createVoucherCode(String redemptionId) {
    final suffix = redemptionId.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    return 'ECO-$suffix';
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
