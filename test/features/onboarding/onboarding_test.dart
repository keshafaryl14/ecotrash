import 'package:ecotrash/app.dart';
import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch can swipe through onboarding and start', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EcoTrashApp()));
    await tester.pumpAndSettle();

    expect(find.text('Pilah dari rumah'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('onboarding-pages')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Setor ke bank sampah'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('onboarding-pages')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kumpulkan poin'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-action')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppStorageKeys.onboardingCompleted), isTrue);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });

  testWidgets('skip completes onboarding and routes to login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EcoTrashApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });
}
