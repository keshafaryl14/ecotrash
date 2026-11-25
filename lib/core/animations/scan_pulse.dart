import 'dart:math' as math;

import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:flutter/material.dart';

class ScanPulse extends StatelessWidget {
  const ScanPulse({
    this.size = 180,
    this.enabled = true,
    this.child,
    super.key,
  });

  final double size;
  final bool enabled;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        EcoLoopPainter(
          width: size,
          height: size,
          duration: const Duration(seconds: 3),
          enabled: enabled,
          semanticsLabel: 'Gelombang pemindaian',
          painterBuilder: (animation) =>
              _ScanPainter(animation, Theme.of(context).colorScheme.primary),
        ),
        child ??
            Icon(
              Icons.document_scanner_outlined,
              size: size * 0.3,
              color: Theme.of(context).colorScheme.primary,
            ),
      ],
    ),
  );
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var index = 0; index < 3; index++) {
      final progress = (animation.value + index / 3) % 1;
      canvas.drawCircle(
        center,
        size.shortestSide * 0.12 + progress * size.shortestSide * 0.35,
        Paint()
          ..color = color.withValues(alpha: (1 - progress) * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final lineProgress = (math.sin(animation.value * math.pi * 2) + 1) / 2;
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * (0.28 + lineProgress * 0.44)),
      Offset(size.width * 0.75, size.height * (0.28 + lineProgress * 0.44)),
      Paint()
        ..color = color.withValues(alpha: 0.65)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) =>
      oldDelegate.color != color;
}
