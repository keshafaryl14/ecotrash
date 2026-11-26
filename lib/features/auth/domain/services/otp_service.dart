abstract interface class OtpService {
  Future<String> sendCode({required String destination});
  Future<bool> verifyCode({required String destination, required String code});
  Future<void> reset();
}

class MockOtpService implements OtpService {
  MockOtpService({this.demo = true});

  final bool demo;
  final Map<String, _OtpChallenge> _challenges = {};
  final Map<String, int> _wrongAttempts = {};

  @override
  Future<String> sendCode({required String destination}) async {
    final code = ((destination.hashCode.abs() % 900000) + 100000).toString();
    _challenges[destination] = _OtpChallenge(
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    _wrongAttempts[destination] = 0;
    // TODO: Replace with Firebase Phone Auth, Twilio/Zenziva, or email gateway.
    if (demo) return code;
    return code;
  }

  @override
  Future<bool> verifyCode({
    required String destination,
    required String code,
  }) async {
    final challenge = _challenges[destination];
    if (challenge == null || DateTime.now().isAfter(challenge.expiresAt)) {
      return false;
    }
    final attempts = (_wrongAttempts[destination] ?? 0) + 1;
    _wrongAttempts[destination] = attempts;
    if (attempts > 5) return false;
    return challenge.code == code;
  }

  @override
  Future<void> reset() async => _challenges.clear();
}

class _OtpChallenge {
  const _OtpChallenge({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}
