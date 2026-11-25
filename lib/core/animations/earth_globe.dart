import 'dart:math' as math;

import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:flutter/material.dart';

class EarthGlobe extends StatelessWidget {
  const EarthGlobe({this.size = 176, this.enabled = true, super.key});

  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) => EcoLoopPainter(
    width: size,
    height: size,
    duration: const Duration(seconds: 18),
    enabled: enabled,
    semanticsLabel: 'Ilustrasi bumi berputar perlahan',
    painterBuilder: (animation) => _EarthPainter(
      animation,
      Theme.of(context).colorScheme,
      Theme.of(context).extension<EcoColors>()!,
    ),
  );
}

class _EarthPainter extends CustomPainter {
  _EarthPainter(this.animation, this.scheme, this.ecoColors)
    : super(repaint: animation);

  final Animation<double> animation;
  final ColorScheme scheme;
  final EcoColors ecoColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.43;
    final sphere = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius * 1.08,
      Paint()..color = scheme.primary.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ecoColors.info, scheme.tertiary],
        ).createShader(sphere),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    canvas.translate(center.dx, center.dy);
    canvas.rotate((animation.value * 2 * math.pi) - math.pi / 4);
    final landPaint = Paint()..color = ecoColors.organic;
    final highlightPaint = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.08);
    _drawLand(canvas, landPaint, radius);
    for (var index = -2; index <= 2; index++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(index * radius * 0.38, 0),
          width: radius * 0.44,
          height: radius * 1.92,
        ),
        highlightPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = scheme.onSurface.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawLand(Canvas canvas, Paint paint, double radius) {
    final northAmerica = Path()
      ..moveTo(-0.74 * radius, -0.22 * radius)
      ..cubicTo(
        -0.55 * radius,
        -0.68 * radius,
        -0.18 * radius,
        -0.62 * radius,
        -0.1 * radius,
        -0.32 * radius,
      )
      ..cubicTo(
        -0.2 * radius,
        -0.1 * radius,
        -0.43 * radius,
        0.02 * radius,
        -0.48 * radius,
        0.27 * radius,
      )
      ..cubicTo(
        -0.73 * radius,
        0.2 * radius,
        -0.88 * radius,
        0,
        -0.74 * radius,
        -0.22 * radius,
      )
      ..close();
    final southAmerica = Path()
      ..moveTo(-0.26 * radius, 0.13 * radius)
      ..cubicTo(
        0.03 * radius,
        0.18 * radius,
        0.05 * radius,
        0.46 * radius,
        -0.08 * radius,
        0.86 * radius,
      )
      ..cubicTo(
        -0.22 * radius,
        0.76 * radius,
        -0.34 * radius,
        0.42 * radius,
        -0.26 * radius,
        0.13 * radius,
      )
      ..close();
    final africa = Path()
      ..moveTo(0.03 * radius, -0.23 * radius)
      ..cubicTo(
        0.42 * radius,
        -0.38 * radius,
        0.49 * radius,
        0.13 * radius,
        0.26 * radius,
        0.57 * radius,
      )
      ..cubicTo(
        0.02 * radius,
        0.46 * radius,
        -0.09 * radius,
        0.03 * radius,
        0.03 * radius,
        -0.23 * radius,
      )
      ..close();
    final asia = Path()
      ..moveTo(0.22 * radius, -0.58 * radius)
      ..cubicTo(
        0.64 * radius,
        -0.78 * radius,
        0.93 * radius,
        -0.28 * radius,
        0.7 * radius,
        0.06 * radius,
      )
      ..cubicTo(
        0.44 * radius,
        0.09 * radius,
        0.39 * radius,
        -0.12 * radius,
        0.17 * radius,
        -0.18 * radius,
      )
      ..close();
    canvas
      ..drawPath(northAmerica, paint)
      ..drawPath(southAmerica, paint)
      ..drawPath(africa, paint)
      ..drawPath(asia, paint);
  }

  @override
  bool shouldRepaint(covariant _EarthPainter oldDelegate) =>
      oldDelegate.scheme != scheme || oldDelegate.ecoColors != ecoColors;
}
