import 'package:flutter/material.dart';

class TruckRoute extends StatelessWidget {
  const TruckRoute({required this.progress, this.enabled = true, super.key});

  final double progress;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0, 1).toDouble();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Progres kurir ${(value * 100).round()} persen',
      child: SizedBox(
        height: 42,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: MediaQuery.of(context).disableAnimations || !enabled
              ? Duration.zero
              : const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, current, child) => LayoutBuilder(
            builder: (context, constraints) => CustomPaint(
              size: Size(constraints.maxWidth, 42),
              painter: _TruckPainter(current, scheme),
            ),
          ),
        ),
      ),
    );
  }
}

class _TruckPainter extends CustomPainter {
  const _TruckPainter(this.progress, this.scheme);

  final double progress;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.62;
    final routePaint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(12, baseline),
      Offset(size.width - 12, baseline),
      routePaint,
    );
    canvas.drawLine(
      Offset(12, baseline),
      Offset(12 + (size.width - 24) * progress, baseline),
      Paint()
        ..color = scheme.primary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final truckX = 12 + (size.width - 40) * progress;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(truckX, baseline - 22, 27, 15),
        const Radius.circular(4),
      ),
      Paint()..color = scheme.primary,
    );
    canvas.drawCircle(
      Offset(truckX + 6, baseline - 3),
      4,
      Paint()..color = scheme.onSurface,
    );
    canvas.drawCircle(
      Offset(truckX + 22, baseline - 3),
      4,
      Paint()..color = scheme.onSurface,
    );
  }

  @override
  bool shouldRepaint(covariant _TruckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.scheme != scheme;
}
