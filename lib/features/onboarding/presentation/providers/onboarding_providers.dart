import 'package:ecotrash/features/onboarding/data/repositories/local_onboarding_repository.dart';
import 'package:ecotrash/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return LocalOnboardingRepository();
});

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> complete() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(onboardingRepositoryProvider).completeOnboarding(),
    );
    state = result;
    return !result.hasError;
  }
}
