import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reduce-motion accessibility keeps loop illustrations still', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final samples = <double>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: EcoLoopPainter(
              width: 40,
              height: 40,
              painterBuilder: (animation) {
                samples.add(animation.value);
                return _ProbePainter();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final initialValue = samples.last;
    await tester.pump(const Duration(seconds: 2));

    expect(samples.last, initialValue);
  });

  testWidgets('profile animation preference pauses loop illustrations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'eco_theme_preferences': '{"mode":"system","colorStyle":"earth","customSeed":774778,"earthAnimationsEnabled":false}',
    });
    final samples = <double>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EcoLoopPainter(
            width: 40,
            height: 40,
            painterBuilder: (animation) {
              samples.add(animation.value);
              return _ProbePainter();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(samples.last, 0);
  });

  testWidgets('enabled loop illustrations animate', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final samples = <double>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: MaterialApp(
            home: EcoLoopPainter(
              width: 40,
              height: 40,
              painterBuilder: (animation) {
                samples.add(animation.value);
                return _ProbePainter();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(samples.last, greaterThan(0));
  });
}

class _ProbePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant _ProbePainter oldDelegate) => false;
}
