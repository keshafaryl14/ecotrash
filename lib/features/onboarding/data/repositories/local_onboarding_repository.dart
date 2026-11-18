import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalOnboardingRepository implements OnboardingRepository {
  @override
  Future<bool> hasCompletedOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(AppStorageKeys.onboardingCompleted) ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(
      AppStorageKeys.onboardingCompleted,
      true,
    );
    if (!saved) {
      throw const OnboardingException(
        'Status perkenalan tidak dapat disimpan. Coba lagi.',
      );
    }
  }
}
