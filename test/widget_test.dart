import 'package:ecotrash/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EcoTrash opens and all five tabs navigate', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EcoTrashApp()));

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
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kelola akun dan preferensi EcoTrash-mu.'),
      findsOneWidget,
    );
  });

  testWidgets('theme follows the system brightness', (tester) async {
    final platformDispatcher = tester.binding.platformDispatcher;
    platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const ProviderScope(child: EcoTrashApp()));
    var scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldContext).brightness, Brightness.light);

    platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    scaffoldContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffoldContext).brightness, Brightness.dark);
  });
}
