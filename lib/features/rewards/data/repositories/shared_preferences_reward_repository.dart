import 'dart:convert';

import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/repositories/reward_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesRewardRepository implements RewardRepository {
  static const _vouchersKey = 'eco_reward_vouchers';

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
  Future<void> saveVoucher(RewardVoucher voucher) async {
    final vouchers = await getVouchers();
    if (vouchers.any((saved) => saved.id == voucher.id)) {
      return;
    }
    await _save([...vouchers, voucher]);
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
