import 'package:ecotrash/features/rewards/domain/entities/reward.dart';

abstract interface class RewardRepository {
  Future<List<RewardVoucher>> getVouchers();

  Future<RewardVoucher?> getVoucher(String voucherId);

  Future<void> saveVoucher(RewardVoucher voucher);

  Future<void> updateVoucher(RewardVoucher voucher);

  Future<void> markVoucherUsed(String voucherId);

  Future<int?> getRemainingStock(Reward reward);

  Future<int> getRedemptionsOn(DateTime day);

  Future<String?> getLastEwalletPhone();

  Future<void> saveLastEwalletPhone(String phone);
}
