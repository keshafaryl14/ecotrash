import 'package:dynamic_color/dynamic_color.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';

abstract final class AppColorSchemes {
  static const earthGreen = Color(0xFF2E7D32);
  static const palettes = <ThemeSeed>[
    ThemeSeed(name: 'Hijau', color: earthGreen),
    ThemeSeed(name: 'Toska', color: Color(0xFF00796B)),
    ThemeSeed(name: 'Biru laut', color: Color(0xFF1565C0)),
    ThemeSeed(name: 'Kuning', color: Color(0xFF9A6700)),
    ThemeSeed(name: 'Terracotta', color: Color(0xFFAD4F2D)),
  ];

  static ColorScheme resolve({
    required Brightness brightness,
    required ThemeColorStyle style,
    required ColorScheme? dynamicScheme,
    required int customSeed,
  }) {
    if (style == ThemeColorStyle.dynamic && dynamicScheme != null) {
      return dynamicScheme.harmonized();
    }
    final seed = style == ThemeColorStyle.custom
        ? Color(customSeed)
        : earthGreen;
    return ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  }
}

@immutable
class ThemeSeed {
  const ThemeSeed({required this.name, required this.color});

  final String name;
  final Color color;
}
