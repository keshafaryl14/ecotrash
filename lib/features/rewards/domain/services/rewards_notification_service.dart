import 'package:ecotrash/features/rewards/domain/entities/reward.dart';

abstract interface class RewardsNotificationService {
  Future<bool> requestPermission();

  Future<void> redemptionSucceeded(RewardVoucher voucher);

  Future<void> scheduleExpiryReminder(RewardVoucher voucher);
}
