import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/widgets/app_shell.dart';
import 'package:ecotrash/features/auth/presentation/auth_page.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:ecotrash/features/auth/presentation/register_page.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/waste_bank_directory_page.dart';
import 'package:ecotrash/features/education/presentation/education_page.dart';
import 'package:ecotrash/features/home/presentation/home_page.dart';
import 'package:ecotrash/features/onboarding/presentation/onboarding_page.dart';
import 'package:ecotrash/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_page.dart';
import 'package:ecotrash/features/profile/presentation/profile_page.dart';
import 'package:ecotrash/features/rewards/presentation/rewards_page.dart';
import 'package:ecotrash/features/smart_scan/presentation/smart_scan_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) async {
      final path = state.uri.path;
      final onboardingComplete = await ref
          .read(onboardingRepositoryProvider)
          .hasCompletedOnboarding();

      if (!onboardingComplete) {
        return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      final isAuthRoute = path == AppRoutes.login || path == AppRoutes.register;

      if (user == null) {
        if (isAuthRoute) {
          return null;
        }
        return AppRoutes.login;
      }

      if (isAuthRoute || path == AppRoutes.onboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentLocation: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.scan,
            builder: (context, state) => const SmartScanPage(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) => const WasteBankDirectoryPage(),
          ),
          GoRoute(
            path: AppRoutes.pickup,
            builder: (context, state) => const PickupPage(),
          ),
          GoRoute(
            path: AppRoutes.rewards,
            builder: (context, state) => const RewardsPage(),
          ),
          GoRoute(
            path: AppRoutes.education,
            builder: (context, state) => const EducationPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
