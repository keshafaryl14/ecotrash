abstract interface class EwalletPayoutService {
  Future<String> createPayoutCode({
    required String redemptionId,
    required int amountRupiah,
  });
}
