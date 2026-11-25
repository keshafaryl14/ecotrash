import 'dart:math' as math;

import 'package:ecotrash/core/animations/earth_globe.dart';
import 'package:ecotrash/core/animations/eco_loop_painter.dart';
import 'package:ecotrash/core/animations/falling_leaves.dart';
import 'package:flutter/material.dart';

class SunCloudBanner extends StatelessWidget {
  const SunCloudBanner({
    required this.title,
    required this.subtitle,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hour = TimeOfDay.now().hour;
    final isNight =
        Theme.of(context).brightness == Brightness.dark ||
        hour < 6 ||
        hour >= 19;
    final sky = isNight ? scheme.surfaceContainerHigh : scheme.primaryContainer;
    final foreground = isNight ? scheme.onSurface : scheme.onPrimaryContainer;

    return Card(
      color: sky,
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            Positioned.fill(
              child: EcoLoopPainter(
                width: 360,
                height: 190,
                duration: const Duration(seconds: 20),
                enabled: enabled,
                painterBuilder: (animation) =>
                    _SkyPainter(animation, scheme, isNight),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: EarthGlobe(size: 92, enabled: enabled),
            ),
            Positioned(
              left: 18,
              top: 16,
              child: FallingLeaves(
                width: 180,
                height: 120,
                count: 5,
                enabled: enabled,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.58,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.animation, this.scheme, this.isNight)
    : super(repaint: animation);

  final Animation<double> animation;
  final ColorScheme scheme;
  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    final motion = animation.value * size.width;
    final sunColor = scheme.tertiary;
    if (isNight) {
      for (var index = 0; index < 14; index++) {
        final x = ((index * 0.37) % 1) * size.width;
        final y = ((index * 0.61) % 1) * size.height * 0.72;
        final twinkle =
            0.35 + (math.sin(animation.value * math.pi * 2 + index) + 1) * 0.25;
        canvas.drawCircle(
          Offset(x, y),
          1.4,
          Paint()..color = scheme.onSurface.withValues(alpha: twinkle),
        );
      }
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.27),
        19,
        Paint()..color = sunColor.withValues(alpha: 0.82),
      );
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.22),
        17,
        Paint()..color = scheme.surfaceContainerHigh,
      );
    } else {
      final sunCenter = Offset(
        size.width * 0.78,
        size.height * 0.28 + math.sin(animation.value * math.pi * 2) * 3,
      );
      canvas.drawCircle(
        sunCenter,
        21,
        Paint()..color = sunColor.withValues(alpha: 0.25),
      );
      canvas.drawCircle(sunCenter, 13, Paint()..color = sunColor);
      for (var index = 0; index < 2; index++) {
        final x = (motion + index * size.width * 0.68) % (size.width + 90) - 45;
        final cloud = Paint()..color = scheme.surface.withValues(alpha: 0.48);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, size.height * (0.32 + index * 0.2)),
            width: 78,
            height: 20,
          ),
          cloud,
        );
        canvas.drawCircle(
          Offset(x - 15, size.height * (0.3 + index * 0.2)),
          13,
          cloud,
        );
        canvas.drawCircle(
          Offset(x + 9, size.height * (0.28 + index * 0.2)),
          16,
          cloud,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) =>
      oldDelegate.scheme != scheme || oldDelegate.isNight != isNight;
}
