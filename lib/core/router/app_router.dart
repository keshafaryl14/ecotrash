import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/widgets/app_shell.dart';
import 'package:ecotrash/features/auth/presentation/auth_page.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:ecotrash/features/auth/presentation/register_page.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/waste_bank_directory_page.dart';
import 'package:ecotrash/features/education/presentation/education_page.dart';
import 'package:ecotrash/features/education/domain/entities/education_article.dart';
import 'package:ecotrash/features/education/presentation/education_article_page.dart';
import 'package:ecotrash/features/education/presentation/education_quiz_page.dart';
import 'package:ecotrash/features/home/presentation/home_page.dart';
import 'package:ecotrash/features/onboarding/presentation/onboarding_page.dart';
import 'package:ecotrash/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_page.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_order_detail_page.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_order_form_page.dart';
import 'package:ecotrash/features/profile/presentation/profile_page.dart';
import 'package:ecotrash/features/rewards/presentation/rewards_page.dart';
import 'package:ecotrash/features/rewards/presentation/rewards_vouchers_page.dart';
import 'package:ecotrash/features/smart_scan/presentation/scan_result_page.dart';
import 'package:ecotrash/features/smart_scan/presentation/smart_scan_page.dart';
import 'package:ecotrash/features/waste_bank_directory/domain/entities/waste_bank.dart';
import 'package:ecotrash/features/waste_bank_directory/presentation/waste_bank_detail_page.dart';
import 'package:flutter/material.dart';
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
      GoRoute(
        path: AppRoutes.scanResult,
        builder: (context, state) {
          final args = state.extra;
          if (args is! ScanResultPageArgs) {
            return const ScanResultRouteErrorPage();
          }
          return ScanResultPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.bankDetail,
        builder: (context, state) {
          final bank = state.extra;
          if (bank is! WasteBank) {
            return const WasteBankDetailErrorPage();
          }
          return WasteBankDetailPage(bank: bank);
        },
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
            path: AppRoutes.pickupNew,
            builder: (context, state) => PickupOrderFormPage(
              prefill: state.extra is PickupFormPrefill
                  ? state.extra! as PickupFormPrefill
                  : null,
            ),
          ),
          GoRoute(
            path: AppRoutes.pickupDetail,
            builder: (context, state) =>
                PickupOrderDetailPage(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.rewards,
            builder: (context, state) => const RewardsPage(),
          ),
          GoRoute(
            path: AppRoutes.rewardVouchers,
            builder: (context, state) => const RewardsVouchersPage(),
          ),
          GoRoute(
            path: AppRoutes.education,
            builder: (context, state) => const EducationPage(),
          ),
          GoRoute(
            path: AppRoutes.educationArticle,
            pageBuilder: (context, state) {
              final article = EducationArticle.bySlug(
                state.pathParameters['slug']!,
              );
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: article == null
                    ? const EducationArticleNotFoundPage()
                    : EducationArticlePage(article: article),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      final position = Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: position,
                          child: child,
                        ),
                      );
                    },
              );
            },
          ),
          GoRoute(
            path: AppRoutes.educationQuiz,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const EducationQuizPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) => FadeTransition(opacity: animation, child: child),
            ),
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
