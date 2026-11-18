abstract interface class OnboardingRepository {
  Future<bool> hasCompletedOnboarding();

  Future<void> completeOnboarding();
}

class OnboardingException implements Exception {
  const OnboardingException(this.message);

  final String message;

  @override
  String toString() => message;
}
