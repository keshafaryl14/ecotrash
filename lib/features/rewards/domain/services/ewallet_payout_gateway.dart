abstract interface class EwalletPayoutGateway {
  Future<String> transfer({
    required String redemptionId,
    required String provider,
    required String phoneNumber,
    required int amountRupiah,
  });
}

bool isValidIndonesianPhone(String value) {
  final normalized = value.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{6,11}$').hasMatch(normalized);
}

String maskIndonesianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) {
    return value;
  }
  return '${digits.substring(0, 4)}****${digits.substring(digits.length - 3)}';
}

const supportedEwalletProviders = [
  'GoPay',
  'OVO',
  'DANA',
  'ShopeePay',
  'LinkAja',
];
