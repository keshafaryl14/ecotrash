import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

@immutable
class EcoColors extends ThemeExtension<EcoColors> {
  const EcoColors({
    required this.organic,
    required this.organicContainer,
    required this.onOrganicContainer,
    required this.inorganic,
    required this.inorganicContainer,
    required this.onInorganicContainer,
    required this.hazardous,
    required this.hazardousContainer,
    required this.onHazardousContainer,
    required this.points,
    required this.pointsContainer,
    required this.onPointsContainer,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  final Color organic;
  final Color organicContainer;
  final Color onOrganicContainer;
  final Color inorganic;
  final Color inorganicContainer;
  final Color onInorganicContainer;
  final Color hazardous;
  final Color hazardousContainer;
  final Color onHazardousContainer;
  final Color points;
  final Color pointsContainer;
  final Color onPointsContainer;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  factory EcoColors.from(ColorScheme scheme) {
    final organic = const Color(0xFF2E7D32).harmonizeWith(scheme.primary);
    final inorganic = const Color(0xFF1565C0).harmonizeWith(scheme.primary);
    final points = const Color(0xFFB36B00).harmonizeWith(scheme.primary);
    final success = const Color(0xFF2E7D32).harmonizeWith(scheme.primary);
    final warning = const Color(0xFF9A5B00).harmonizeWith(scheme.primary);
    final info = const Color(0xFF1565C0).harmonizeWith(scheme.primary);

    return EcoColors(
      organic: organic,
      organicContainer: _containerFor(organic, scheme.surface),
      onOrganicContainer: _onColor(_containerFor(organic, scheme.surface)),
      inorganic: inorganic,
      inorganicContainer: _containerFor(inorganic, scheme.surface),
      onInorganicContainer: _onColor(_containerFor(inorganic, scheme.surface)),
      hazardous: scheme.error,
      hazardousContainer: scheme.errorContainer,
      onHazardousContainer: scheme.onErrorContainer,
      points: points,
      pointsContainer: _containerFor(points, scheme.surface),
      onPointsContainer: _onColor(_containerFor(points, scheme.surface)),
      success: success,
      onSuccess: _onColor(success),
      warning: warning,
      onWarning: _onColor(warning),
      info: info,
      onInfo: _onColor(info),
    );
  }

  static Color _containerFor(Color color, Color surface) =>
      Color.alphaBlend(color.withValues(alpha: 0.14), surface);

  static Color _onColor(Color background) {
    final whiteContrast = contrastRatio(background, Colors.white);
    final blackContrast = contrastRatio(background, Colors.black);
    return whiteContrast >= blackContrast ? Colors.white : Colors.black;
  }

  static double contrastRatio(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  @override
  EcoColors copyWith({
    Color? organic,
    Color? organicContainer,
    Color? onOrganicContainer,
    Color? inorganic,
    Color? inorganicContainer,
    Color? onInorganicContainer,
    Color? hazardous,
    Color? hazardousContainer,
    Color? onHazardousContainer,
    Color? points,
    Color? pointsContainer,
    Color? onPointsContainer,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) => EcoColors(
    organic: organic ?? this.organic,
    organicContainer: organicContainer ?? this.organicContainer,
    onOrganicContainer: onOrganicContainer ?? this.onOrganicContainer,
    inorganic: inorganic ?? this.inorganic,
    inorganicContainer: inorganicContainer ?? this.inorganicContainer,
    onInorganicContainer: onInorganicContainer ?? this.onInorganicContainer,
    hazardous: hazardous ?? this.hazardous,
    hazardousContainer: hazardousContainer ?? this.hazardousContainer,
    onHazardousContainer: onHazardousContainer ?? this.onHazardousContainer,
    points: points ?? this.points,
    pointsContainer: pointsContainer ?? this.pointsContainer,
    onPointsContainer: onPointsContainer ?? this.onPointsContainer,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
  );

  @override
  EcoColors lerp(ThemeExtension<EcoColors>? other, double t) {
    if (other is! EcoColors) {
      return this;
    }
    return EcoColors(
      organic: Color.lerp(organic, other.organic, t)!,
      organicContainer: Color.lerp(
        organicContainer,
        other.organicContainer,
        t,
      )!,
      onOrganicContainer: Color.lerp(
        onOrganicContainer,
        other.onOrganicContainer,
        t,
      )!,
      inorganic: Color.lerp(inorganic, other.inorganic, t)!,
      inorganicContainer: Color.lerp(
        inorganicContainer,
        other.inorganicContainer,
        t,
      )!,
      onInorganicContainer: Color.lerp(
        onInorganicContainer,
        other.onInorganicContainer,
        t,
      )!,
      hazardous: Color.lerp(hazardous, other.hazardous, t)!,
      hazardousContainer: Color.lerp(
        hazardousContainer,
        other.hazardousContainer,
        t,
      )!,
      onHazardousContainer: Color.lerp(
        onHazardousContainer,
        other.onHazardousContainer,
        t,
      )!,
      points: Color.lerp(points, other.points, t)!,
      pointsContainer: Color.lerp(pointsContainer, other.pointsContainer, t)!,
      onPointsContainer: Color.lerp(
        onPointsContainer,
        other.onPointsContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}
