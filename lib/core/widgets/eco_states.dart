import 'dart:math' as math;

import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:flutter/material.dart';

enum EcoEmptyIllustration { emptyBin, error, noLocation }

class EcoEmptyState extends StatelessWidget {
  const EcoEmptyState({
    required this.title,
    required this.message,
    this.illustration = EcoEmptyIllustration.emptyBin,
    this.actionLabel,
    this.onAction,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String message;
  final EcoEmptyIllustration illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EcoLoopPainter(
            width: 124,
            height: 110,
            duration: const Duration(seconds: 9),
            enabled: enabled,
            semanticsLabel: switch (illustration) {
              EcoEmptyIllustration.emptyBin => 'Ilustrasi tempat sampah kosong',
              EcoEmptyIllustration.error => 'Ilustrasi gangguan',
              EcoEmptyIllustration.noLocation => 'Ilustrasi pin lokasi',
            },
            painterBuilder: (animation) => _EcoStatePainter(
              animation,
              illustration,
              Theme.of(context).colorScheme,
              Theme.of(context).extension<EcoColors>()!,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class EcoErrorState extends StatelessWidget {
  const EcoErrorState({
    required this.message,
    this.onRetry,
    this.enabled = true,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool enabled;

  @override
  Widget build(BuildContext context) => EcoEmptyState(
    title: 'Ada kendala',
    message: message,
    illustration: EcoEmptyIllustration.error,
    actionLabel: onRetry == null ? null : 'Coba lagi',
    onAction: onRetry,
    enabled: enabled,
  );
}

class _EcoStatePainter extends CustomPainter {
  _EcoStatePainter(this.animation, this.type, this.scheme, this.eco)
    : super(repaint: animation);

  final Animation<double> animation;
  final EcoEmptyIllustration type;
  final ColorScheme scheme;
  final EcoColors eco;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final motion = animation.value * 2 - 1;
    switch (type) {
      case EcoEmptyIllustration.emptyBin:
        final bin = Paint()
          ..color = scheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - 26, 34),
          Offset(center.dx + 26, 34),
          bin,
        );
        canvas.drawLine(
          Offset(center.dx - 20, 39),
          Offset(center.dx - 16, 86),
          bin,
        );
        canvas.drawLine(
          Offset(center.dx + 20, 39),
          Offset(center.dx + 16, 86),
          bin,
        );
        canvas.drawLine(
          Offset(center.dx - 16, 86),
          Offset(center.dx + 16, 86),
          bin,
        );
        canvas.drawLine(
          Offset(center.dx - 8 + motion * 2, 20),
          Offset(center.dx + 10 + motion * 2, 20),
          Paint()
            ..color = eco.organic
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + motion * 9, 12),
            width: 17,
            height: 8,
          ),
          Paint()..color = eco.organic,
        );
      case EcoEmptyIllustration.error:
        final color = eco.warning;
        final shake = math.sin(motion * 12) * 4;
        canvas.drawLine(
          Offset(center.dx - 27 + shake, 24),
          Offset(center.dx - 27 + shake, 72),
          Paint()
            ..color = color
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(center.dx + 27 + shake, 24),
          Offset(center.dx + 27 + shake, 72),
          Paint()
            ..color = color
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(center.dx - 23 + shake, 72),
          Offset(center.dx + 23 + shake, 72),
          Paint()
            ..color = color
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(center.dx - 3 + shake, 38),
          Offset(center.dx + 4 + shake, 49),
          Paint()
            ..color = scheme.error
            ..strokeWidth = 4,
        );
        canvas.drawLine(
          Offset(center.dx + 4 + shake, 49),
          Offset(center.dx - 3 + shake, 60),
          Paint()
            ..color = scheme.error
            ..strokeWidth = 4,
        );
      case EcoEmptyIllustration.noLocation:
        final radius = 4 + ((animation.value * 17) % 17);
        canvas.drawCircle(
          Offset(center.dx, 80),
          radius.toDouble(),
          Paint()
            ..color = scheme.primary.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final pin = Path()
          ..moveTo(center.dx, 16)
          ..cubicTo(center.dx - 32, 16, center.dx - 30, 55, center.dx, 76)
          ..cubicTo(center.dx + 30, 55, center.dx + 32, 16, center.dx, 16)
          ..close();
        canvas.drawPath(pin, Paint()..color = scheme.primary);
        canvas.drawCircle(
          Offset(center.dx, 36),
          8,
          Paint()..color = scheme.onPrimary,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _EcoStatePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.scheme != scheme ||
      oldDelegate.eco != eco;
}
