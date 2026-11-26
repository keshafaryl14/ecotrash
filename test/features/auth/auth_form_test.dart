import 'package:ecotrash/app.dart';
import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecotrash/features/auth/data/repositories/local_auth_repository.dart';
import 'package:ecotrash/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppStorageKeys.onboardingCompleted: true,
    });
    LocalAuthRepository.resetInMemory();
  });

  testWidgets('login and registration show Indonesian validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsWidgets);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak valid'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);

    await tester.ensureVisible(find.text('Belum punya akun? Daftar'));
    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register-name')), 'Dina');
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'dina@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'pilahsampah1',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-confirmation')),
      'sampahpilah',
    );
    await tester.tap(find.text('Saya menyetujui syarat dan kebijakan privasi'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi belum sama'), findsOneWidget);
  });

  testWidgets('login displays an authentication error', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengguna'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'dina@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'pilahsampah1',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Akun belum terdaftar'), findsOneWidget);
  });

  testWidgets(
    'registration saves the session and opens the personalized home',
    (tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pengguna'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belum punya akun? Daftar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('register-name')), 'Dina');
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'dina@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'pilahsampah1',
      );
      await tester.enterText(
        find.byKey(const Key('register-password-confirmation')),
        'pilahsampah1',
      );
      await tester.tap(
        find.text('Saya menyetujui syarat dan kebijakan privasi'),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('register-submit')));
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Halo, Dina!'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-profile')));
      await tester.pumpAndSettle();
      final signOut = find.byKey(const Key('profile-sign-out'));
      await tester.scrollUntilVisible(
        signOut,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(signOut);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-sign-out-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Masuk sebagai Pengguna'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'dina@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'pilahsampah1',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Dina!'), findsOneWidget);
    },
  );
}

Widget _testApp() => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(
      LocalAuthRepository(inMemory: true),
    ),
  ],
  child: const MediaQuery(
    data: MediaQueryData(disableAnimations: true),
    child: EcoTrashApp(),
  ),
);
