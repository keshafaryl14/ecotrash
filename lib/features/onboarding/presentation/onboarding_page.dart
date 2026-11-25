import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/animations/earth_globe.dart';
import 'package:ecotrash/core/animations/falling_leaves.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:ecotrash/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  var _currentPage = 0;

  static const _pages = [
    _OnboardingStep(
      title: 'Pilah dari rumah',
      description:
          'Kenali jenis sampah dan mulai kebiasaan memilah yang lebih baik.',
      icon: Icons.recycling_outlined,
    ),
    _OnboardingStep(
      title: 'Setor ke bank sampah',
      description:
          'Temukan mitra daur ulang dan salurkan sampahmu dengan mudah.',
      icon: Icons.location_on_outlined,
    ),
    _OnboardingStep(
      title: 'Kumpulkan poin',
      description:
          'Setiap kontribusi membawa manfaat untuk lingkungan dan dirimu.',
      icon: Icons.card_giftcard_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final completed = await ref
        .read(onboardingControllerProvider.notifier)
        .complete();
    if (completed && mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completionState = ref.watch(onboardingControllerProvider);
    final animationsEnabled = ref.watch(earthAnimationsEnabledProvider);
    final isLoading = completionState.isLoading;
    final error = completionState.error;
    final errorMessage = error == null
        ? null
        : error is OnboardingException
        ? error.message
        : 'Perkenalan tidak dapat disimpan. Coba lagi.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selamat datang'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _finishOnboarding,
            child: const Text('Lewati'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const Key('onboarding-pages'),
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final colorScheme = Theme.of(context).colorScheme;
                  return AnimatedContainer(
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    color: index.isEven
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerLow,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 16,
                          right: 0,
                          child: FallingLeaves(
                            width: 180,
                            height: 150,
                            count: 6,
                            enabled: animationsEnabled,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (index == 0)
                                EarthGlobe(
                                  size: 176,
                                  enabled: animationsEnabled,
                                )
                              else
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  foregroundColor:
                                      colorScheme.onSecondaryContainer,
                                  child: Icon(page.icon, size: 48),
                                ),
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final selected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  errorMessage,
                  key: const Key('onboarding-error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding-action'),
                  onPressed: isLoading
                      ? null
                      : _currentPage == _pages.length - 1
                      ? _finishOnboarding
                      : _goToNextPage,
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentPage == _pages.length - 1
                              ? 'Mulai'
                              : 'Berikutnya',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
