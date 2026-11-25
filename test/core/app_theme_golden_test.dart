import 'package:ecotrash/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('EcoTrash core components render in $brightness mode', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 240));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: brightness,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.light
              ? AppTheme.light(scheme)
              : AppTheme.dark(scheme),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) => Text(
                          'Poin Eco kamu',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('240 poin'),
                      const Spacer(),
                      const FilledButton(
                        onPressed: null,
                        child: Text('Tukar poin'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/eco_components_${brightness.name}.png'),
      );
    });
  }
}
