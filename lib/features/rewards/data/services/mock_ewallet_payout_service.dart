import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_service.dart';

class MockEwalletPayoutService implements EwalletPayoutService {
  @override
  Future<String> createPayoutCode({
    required String redemptionId,
    required int amountRupiah,
  }) async {
    // TODO: replace with a backend-backed e-wallet payout gateway.
    final suffix = redemptionId.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    return 'ECO$amountRupiah-$suffix';
  }
}
