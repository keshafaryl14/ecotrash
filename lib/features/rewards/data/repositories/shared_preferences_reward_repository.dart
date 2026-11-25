import 'dart:convert';

import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/repositories/reward_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRewardRepository implements RewardRepository {
  static const _vouchersKey = 'eco_reward_vouchers';
  static const _lastEwalletPhoneKey = 'eco_last_ewallet_phone';

  @override
  Future<List<RewardVoucher>> getVouchers() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_vouchersKey);
    if (stored == null) {
      return [];
    }
    final decoded = jsonDecode(stored);
    if (decoded is! List) {
      throw const FormatException('Data voucher tersimpan tidak valid.');
    }
    return decoded
        .map((raw) => RewardVoucher.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RewardVoucher?> getVoucher(String voucherId) async {
    final vouchers = await getVouchers();
    for (final voucher in vouchers) {
      if (voucher.id == voucherId) {
        return voucher;
      }
    }
    return null;
  }

  @override
  Future<void> saveVoucher(RewardVoucher voucher) async {
    final vouchers = await getVouchers();
    if (vouchers.any(
      (saved) =>
          saved.id == voucher.id ||
          (voucher.redemptionReference != null &&
              saved.redemptionReference == voucher.redemptionReference),
    )) {
      return;
    }
    await _save([...vouchers, voucher]);
  }

  @override
  Future<void> updateVoucher(RewardVoucher voucher) async {
    final vouchers = await getVouchers();
    final index = vouchers.indexWhere((saved) => saved.id == voucher.id);
    if (index < 0) {
      throw const RewardRepositoryException('Voucher tidak ditemukan.');
    }
    vouchers[index] = voucher;
    await _save(vouchers);
  }

  @override
  Future<void> markVoucherUsed(String voucherId) async {
    final vouchers = await getVouchers();
    final index = vouchers.indexWhere((voucher) => voucher.id == voucherId);
    if (index < 0) {
      throw const RewardRepositoryException('Voucher tidak ditemukan.');
    }
    final voucher = vouchers[index];
    if (voucher.status != RewardVoucherStatus.active) {
      throw const RewardRepositoryException(
        'Voucher ini tidak lagi dapat digunakan.',
      );
    }
    vouchers[index] = voucher.copyWith(usedAt: DateTime.now());
    await _save(vouchers);
  }

  @override
  Future<int?> getRemainingStock(Reward reward) async {
    final stock = reward.stock;
    if (stock == null) {
      return null;
    }
    final vouchers = await getVouchers();
    final redeemed = vouchers
        .where(
          (voucher) =>
              voucher.rewardId == reward.id &&
              voucher.status != RewardVoucherStatus.cancelled &&
              voucher.status != RewardVoucherStatus.failed,
        )
        .length;
    return (stock - redeemed).clamp(0, stock);
  }

  @override
  Future<int> getRedemptionsOn(DateTime day) async {
    final vouchers = await getVouchers();
    return vouchers
        .where(
          (voucher) =>
              voucher.createdAt.year == day.year &&
              voucher.createdAt.month == day.month &&
              voucher.createdAt.day == day.day,
        )
        .length;
  }

  @override
  Future<String?> getLastEwalletPhone() async =>
      (await SharedPreferences.getInstance()).getString(_lastEwalletPhoneKey);

  @override
  Future<void> saveLastEwalletPhone(String phone) async {
    final saved = await (await SharedPreferences.getInstance()).setString(
      _lastEwalletPhoneKey,
      phone,
    );
    if (!saved) {
      throw const RewardRepositoryException(
        'Nomor e-wallet tidak dapat disimpan.',
      );
    }
  }

  Future<void> _save(List<RewardVoucher> vouchers) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _vouchersKey,
      jsonEncode(vouchers.map((voucher) => voucher.toJson()).toList()),
    );
    if (!saved) {
      throw const RewardRepositoryException('Voucher tidak dapat disimpan.');
    }
  }
}

class RewardRepositoryException implements Exception {
  const RewardRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
