import 'package:dynamic_color/dynamic_color.dart';
import 'package:ecotrash/core/theme/color_schemes.dart';
import 'package:ecotrash/core/theme/eco_colors.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dynamic scheme is used when requested and available', () {
    final dynamic = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9C27B0),
      brightness: Brightness.light,
    );
    final result = AppColorSchemes.resolve(
      brightness: Brightness.light,
      style: ThemeColorStyle.dynamic,
      dynamicScheme: dynamic,
      customSeed: AppColorSchemes.earthGreen.toARGB32(),
    );

    expect(result.primary, dynamic.harmonized().primary);
    expect(result.secondary, dynamic.harmonized().secondary);
  });

  test('unsupported dynamic color falls back to the Earth seed', () {
    final result = AppColorSchemes.resolve(
      brightness: Brightness.dark,
      style: ThemeColorStyle.dynamic,
      dynamicScheme: null,
      customSeed: AppColorSchemes.earthGreen.toARGB32(),
    );

    expect(
      result,
      ColorScheme.fromSeed(
        seedColor: AppColorSchemes.earthGreen,
        brightness: Brightness.dark,
      ),
    );
  });

  test('custom palette and semantic colors keep readable foregrounds', () {
    final scheme = AppColorSchemes.resolve(
      brightness: Brightness.light,
      style: ThemeColorStyle.custom,
      dynamicScheme: null,
      customSeed: AppColorSchemes.palettes[2].color.toARGB32(),
    );
    final eco = EcoColors.from(scheme);

    expect(scheme.primary, isNot(AppColorSchemes.earthGreen));
    for (final (background, foreground) in [
      (eco.organicContainer, eco.onOrganicContainer),
      (eco.inorganicContainer, eco.onInorganicContainer),
      (eco.hazardousContainer, eco.onHazardousContainer),
      (eco.pointsContainer, eco.onPointsContainer),
      (eco.success, eco.onSuccess),
      (eco.warning, eco.onWarning),
      (eco.info, eco.onInfo),
    ]) {
      expect(
        EcoColors.contrastRatio(background, foreground),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
