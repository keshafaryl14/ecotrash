import 'package:ecotrash/app.dart';
import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppStorageKeys.onboardingCompleted: true,
    });
  });

  testWidgets('login and registration show Indonesian validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsWidgets);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);

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
      'pilahsampah',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-confirmation')),
      'sampahpilah',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);
  });

  testWidgets('login displays an authentication error', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'dina@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'pilahsampah',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi tidak sesuai.'), findsOneWidget);
  });

  testWidgets(
    'registration saves the session and opens the personalized home',
    (tester) async {
      await tester.pumpWidget(_testApp());
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
        'pilahsampah',
      );
      await tester.enterText(
        find.byKey(const Key('register-password-confirmation')),
        'pilahsampah',
      );
      await tester.ensureVisible(find.byKey(const Key('register-submit')));
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Halo, Dina!'), findsOneWidget);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(AppStorageKeys.authUserName), 'Dina');

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
      expect(find.text('Selamat datang kembali'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'dina@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'pilahsampah',
      );
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Dina!'), findsOneWidget);
    },
  );
}

Widget _testApp() => const ProviderScope(
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: true),
    child: EcoTrashApp(),
  ),
);
