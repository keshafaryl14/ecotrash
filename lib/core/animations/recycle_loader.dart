import 'dart:math' as math;

import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:flutter/material.dart';

class RecycleLoader extends StatelessWidget {
  const RecycleLoader({
    this.size = 48,
    this.enabled = true,
    this.semanticsLabel = 'Memuat',
    super.key,
  });

  final double size;
  final bool enabled;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => EcoLoopPainter(
    width: size,
    height: size,
    duration: const Duration(seconds: 3),
    enabled: enabled,
    semanticsLabel: semanticsLabel,
    painterBuilder: (animation) =>
        _RecyclePainter(animation, Theme.of(context).colorScheme),
  );
}

class _RecyclePainter extends CustomPainter {
  _RecyclePainter(this.animation, this.scheme) : super(repaint: animation);

  final Animation<double> animation;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.32;
    final stroke = math.max(2.5, size.shortestSide * 0.075).toDouble();
    final colors = [scheme.primary, scheme.secondary, scheme.tertiary];
    for (var index = 0; index < 3; index++) {
      final start = (animation.value * math.pi * 2) + (index * math.pi * 2 / 3);
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi * 0.47,
        false,
        paint,
      );
      final tipAngle = start + math.pi * 0.47;
      final tip = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      canvas.save();
      canvas.translate(tip.dx, tip.dy);
      canvas.rotate(tipAngle + math.pi / 2);
      final arrow = Path()
        ..moveTo(-stroke * 0.75, -stroke)
        ..lineTo(stroke * 0.9, 0)
        ..lineTo(-stroke * 0.75, stroke)
        ..close();
      canvas.drawPath(arrow, Paint()..color = colors[index]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RecyclePainter oldDelegate) =>
      oldDelegate.scheme != scheme;
}
