import 'package:ecotrash/app.dart';
import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    const permissionsChannel = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, (call) async {
          if (call.method == 'checkPermissionStatus') {
            return 0;
          }
          if (call.method == 'requestPermissions') {
            final permissionIds = call.arguments as List<dynamic>;
            return {for (final id in permissionIds) id as int: 0};
          }
          return false;
        });
    SharedPreferences.setMockInitialValues({
      AppStorageKeys.onboardingCompleted: true,
      AppStorageKeys.authUserId: 'kesha@example.com',
      AppStorageKeys.authUserName: 'Kesha',
      AppStorageKeys.authUserEmail: 'kesha@example.com',
    });
  });

  testWidgets('EcoTrash opens and all five tabs navigate', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EcoTrashApp()));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Kesha!'), findsOneWidget);
    expect(find.text('Poin Eco kamu'), findsOneWidget);

    const destinations = [
      ('Scan', 'Smart Scan'),
      ('Peta', 'Peta Bank Sampah Terdekat'),
      ('Penjemputan', 'Layanan Penjemputan'),
      ('Rewards', 'Rewards & Poin'),
    ];

    for (final (tab, pageTitle) in destinations) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.text(pageTitle), findsOneWidget);
    }

    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.text('kesha@example.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });

  testWidgets('theme follows the system brightness', (tester) async {
    final platformDispatcher = tester.binding.platformDispatcher;
    platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const ProviderScope(child: EcoTrashApp()));
    await tester.pumpAndSettle();
    var scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldContext).brightness, Brightness.light);

    platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
  });
}
