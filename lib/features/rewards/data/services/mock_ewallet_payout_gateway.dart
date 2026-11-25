import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_gateway.dart';
import 'package:ecotrash/features/rewards/domain/services/ewallet_payout_service.dart';

class MockEwalletPayoutGateway implements EwalletPayoutGateway {
  const MockEwalletPayoutGateway(this._service);

  final EwalletPayoutService _service;

  @override
  Future<String> transfer({
    required String redemptionId,
    required String provider,
    required String phoneNumber,
    required int amountRupiah,
  }) {
    // TODO: replace with a server-side payment gateway; never transfer from a
    // mobile client in production.
    return _service.createPayoutCode(
      redemptionId: redemptionId,
      amountRupiah: amountRupiah,
    );
  }
}
