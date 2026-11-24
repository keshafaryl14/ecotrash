import 'package:ecotrash/features/rewards/domain/entities/reward.dart';

abstract interface class RewardRepository {
  Future<List<RewardVoucher>> getVouchers();

  Future<void> saveVoucher(RewardVoucher voucher);

  Future<void> markVoucherUsed(String voucherId);
}
