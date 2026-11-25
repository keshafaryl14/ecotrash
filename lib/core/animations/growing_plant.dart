import 'dart:math' as math;

import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:flutter/material.dart';

class GrowingPlant extends StatelessWidget {
  const GrowingPlant({
    this.progress = 1,
    this.stage = 0,
    this.size = 94,
    this.enabled = true,
    super.key,
  });

  final double progress;
  final int stage;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) => EcoLoopPainter(
    width: size,
    height: size,
    duration: const Duration(seconds: 10),
    enabled: enabled,
    semanticsLabel: 'Ilustrasi tanaman tumbuh sesuai progres',
    painterBuilder: (animation) => _PlantPainter(
      animation,
      progress.clamp(0, 1).toDouble(),
      stage.clamp(0, 2).toInt(),
      Theme.of(context).extension<EcoColors>()!,
      Theme.of(context).colorScheme,
    ),
  );
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(
    this.animation,
    this.progress,
    this.stage,
    this.eco,
    this.scheme,
  ) : super(repaint: animation);

  final Animation<double> animation;
  final double progress;
  final int stage;
  final EcoColors eco;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final ground = size.height * 0.88;
    final growth = progress * (0.78 + (stage * 0.1));
    final height = size.height * growth;
    final trunk = Paint()
      ..color = scheme.tertiary
      ..strokeWidth = math.max(3, size.width * 0.055)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, ground),
      Offset(centerX, ground - height * 0.58),
      trunk,
    );
    if (growth < 0.2) {
      final shoot = Path()
        ..moveTo(centerX, ground - height * 0.58)
        ..quadraticBezierTo(
          centerX - 18,
          ground - height,
          centerX - 24,
          ground - height * 0.82,
        )
        ..moveTo(centerX, ground - height * 0.58)
        ..quadraticBezierTo(
          centerX + 16,
          ground - height,
          centerX + 21,
          ground - height * 0.78,
        );
      canvas.drawPath(
        shoot,
        Paint()
          ..color = eco.organic
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final sway = math.sin(animation.value * math.pi * 2) * 2;
    final leafCount = stage == 0
        ? 4
        : stage == 1
        ? 7
        : 10;
    final leafPaint = Paint()..color = eco.organic;
    final crownY = ground - height * 0.68;
    final crownRadius = size.width * (0.2 + stage * 0.055) * progress;
    for (var index = 0; index < leafCount; index++) {
      final angle = (index / leafCount) * math.pi * 2 + sway * 0.02;
      final radiusX = math.cos(angle) * crownRadius;
      final radiusY = math.sin(angle) * crownRadius * 0.72;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX + radiusX, crownY + radiusY),
          width: crownRadius * 0.75,
          height: crownRadius * 0.45,
        ),
        leafPaint,
      );
    }
    if (stage == 2) {
      final fruitPaint = Paint()..color = eco.points;
      for (var index = 0; index < 3; index++) {
        canvas.drawCircle(
          Offset(
            centerX + (index - 1) * crownRadius * 0.65,
            crownY + crownRadius * 0.35,
          ),
          3.2,
          fruitPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.stage != stage ||
      oldDelegate.eco != eco ||
      oldDelegate.scheme != scheme;
}
