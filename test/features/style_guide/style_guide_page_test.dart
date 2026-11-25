import 'package:ecotrash/core/theme/app_theme.dart';
import 'package:ecotrash/features/style_guide/presentation/style_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('debug style guide renders Material roles and component demos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.light(
              ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
            ),
            home: const StyleGuidePage(),
          ),
        ),
      ),
    );

    expect(find.text('Style Guide EcoTrash'), findsWidgets);
    expect(find.text('Surface highest'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('SearchBar — cari fitur'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('SearchBar — cari fitur'), findsOneWidget);
    expect(find.text('Simulasi poin'), findsOneWidget);
  });
}
