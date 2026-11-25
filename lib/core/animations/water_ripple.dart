import 'dart:math' as math;

import 'package:ecotrash/core/animations/animation_settings.dart';
import 'package:flutter/material.dart';

class WaterRipple extends StatefulWidget {
  const WaterRipple({
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(26)),
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final BorderRadius borderRadius;

  @override
  State<WaterRipple> createState() => _WaterRippleState();
}

class _WaterRippleState extends State<WaterRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (shouldPlayEcoAnimation(context, enabled: widget.enabled)) {
      _controller.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: widget.borderRadius,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        child: Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => CustomPaint(
                    painter: _RipplePainter(
                      _controller.value,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final radius =
        math.sqrt(size.width * size.width + size.height * size.height) *
        progress;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()
        ..color = color.withValues(alpha: (1 - progress) * 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
