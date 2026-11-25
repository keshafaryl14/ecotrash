import 'dart:math' as math;

import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:flutter/material.dart';

class FallingLeaves extends StatelessWidget {
  const FallingLeaves({
    this.width = 220,
    this.height = 140,
    this.count = 8,
    this.enabled = true,
    super.key,
  });

  final double width;
  final double height;
  final int count;
  final bool enabled;

  @override
  Widget build(BuildContext context) => EcoLoopPainter(
    width: width,
    height: height,
    duration: const Duration(seconds: 14),
    enabled: enabled,
    semanticsLabel: 'Daun dekoratif bergerak perlahan',
    painterBuilder: (animation) => _LeavesPainter(
      animation,
      Theme.of(context).extension<EcoColors>()!.organic,
      count.clamp(0, 12).toInt(),
    ),
  );
}

class _LeavesPainter extends CustomPainter {
  _LeavesPainter(this.animation, this.color, this.count)
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.62);
    for (var index = 0; index < count; index++) {
      final seed = index * 0.61803398875;
      final progress = (animation.value + seed) % 1;
      final x =
          ((seed * 1.71) % 1) * size.width +
          math.sin((progress + seed) * math.pi * 2) * 13;
      final y = progress * (size.height + 24) - 12;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(progress * math.pi * 2 + seed) * 0.75);
      canvas.scale(0.65 + ((index % 3) * 0.16));
      final leaf = Path()
        ..moveTo(0, -8)
        ..quadraticBezierTo(10, -5, 6, 4)
        ..quadraticBezierTo(1, 10, -5, 4)
        ..quadraticBezierTo(-9, -3, 0, -8)
        ..close();
      canvas.drawPath(leaf, paint);
      canvas.drawLine(
        const Offset(0, -7),
        const Offset(0, 6),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeavesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.count != count;
}
