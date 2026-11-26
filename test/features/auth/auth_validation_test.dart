import 'package:ecotrash/features/auth/domain/services/otp_service.dart';
import 'package:ecotrash/features/auth/domain/use_cases/auth_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes Indonesian phone formats', () {
    expect(normalizePhone('081234567890'), '+6281234567890');
    expect(normalizePhone('+62 81234567890'), '+6281234567890');
    expect(normalizePhone('6281234567890'), '+6281234567890');
  });

  test('validates email and password', () {
    expect(isValidEmail('nama@example.com'), isTrue);
    expect(isValidEmail('nama@'), isFalse);
    expect(isValidPassword('sampah123'), isTrue);
    expect(isValidPassword('sampah'), isFalse);
  });

  test('mock OTP accepts correct code and rejects wrong code', () async {
    final service = MockOtpService();
    final code = await service.sendCode(destination: '+6281234567890');
    expect(
      await service.verifyCode(destination: '+6281234567890', code: code),
      isTrue,
    );
    expect(
      await service.verifyCode(destination: '+6281234567890', code: '000000'),
      isFalse,
    );
  });
}
