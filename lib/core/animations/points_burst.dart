import 'dart:math' as math;

import 'package:ecotrash/core/animations/animation_settings.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PointsBurst extends StatefulWidget {
  const PointsBurst({
    required this.points,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final int points;
  final Widget child;
  final bool enabled;

  @override
  State<PointsBurst> createState() => _PointsBurstState();
}

class _PointsBurstState extends State<PointsBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _previousPoints = 0;
  var _canAnimate = true;

  @override
  void initState() {
    super.initState();
    _previousPoints = widget.points;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canAnimate = shouldPlayEcoAnimation(context, enabled: widget.enabled);
  }

  @override
  void didUpdateWidget(covariant PointsBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    _canAnimate = shouldPlayEcoAnimation(context, enabled: widget.enabled);
    if (widget.points > _previousPoints && _canAnimate) {
      _controller.forward(from: 0);
      HapticFeedback.selectionClick();
    }
    _previousPoints = widget.points;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _BurstPainter(
                _controller.value,
                Theme.of(context).extension<EcoColors>()!.points,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    for (var index = 0; index < 9; index++) {
      final angle = index * math.pi * 2 / 9;
      final distance = progress * math.min(size.width, size.height) * 0.48;
      final point = Offset(
        size.width / 2 + math.cos(angle) * distance,
        size.height / 2 + math.sin(angle) * distance,
      );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
        Paint()..color = color.withValues(alpha: 1 - progress),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
