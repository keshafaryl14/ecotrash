import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColorStyle { dynamic, earth, custom }

enum ThemeModeChoice { system, light, dark, amoled }

@immutable
class ThemePreferences {
  const ThemePreferences({
    this.mode = ThemeModeChoice.system,
    this.colorStyle = ThemeColorStyle.dynamic,
    this.customSeed = 0xFF2E7D32,
    this.earthAnimationsEnabled = true,
  });

  final ThemeModeChoice mode;
  final ThemeColorStyle colorStyle;
  final int customSeed;
  final bool earthAnimationsEnabled;

  ThemeMode get themeMode => switch (mode) {
    ThemeModeChoice.system => ThemeMode.system,
    ThemeModeChoice.light => ThemeMode.light,
    ThemeModeChoice.dark || ThemeModeChoice.amoled => ThemeMode.dark,
  };

  bool get amoled => mode == ThemeModeChoice.amoled;

  ThemePreferences copyWith({
    ThemeModeChoice? mode,
    ThemeColorStyle? colorStyle,
    int? customSeed,
    bool? earthAnimationsEnabled,
  }) => ThemePreferences(
    mode: mode ?? this.mode,
    colorStyle: colorStyle ?? this.colorStyle,
    customSeed: customSeed ?? this.customSeed,
    earthAnimationsEnabled:
        earthAnimationsEnabled ?? this.earthAnimationsEnabled,
  );

  @override
  bool operator ==(Object other) =>
      other is ThemePreferences &&
      other.mode == mode &&
      other.colorStyle == colorStyle &&
      other.customSeed == customSeed &&
      other.earthAnimationsEnabled == earthAnimationsEnabled;

  @override
  int get hashCode =>
      Object.hash(mode, colorStyle, customSeed, earthAnimationsEnabled);
}

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemePreferences>(
      ThemeController.new,
    );

final earthAnimationsEnabledProvider = Provider<bool>((ref) {
  return ref
          .watch(themeControllerProvider)
          .asData
          ?.value
          .earthAnimationsEnabled ??
      true;
});

class ThemeController extends AsyncNotifier<ThemePreferences> {
  static const _storageKey = 'eco_theme_preferences';
  static const _legacyModeKey = 'eco_theme_mode';

  @override
  Future<ThemePreferences> build() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Pengaturan tampilan tidak valid.');
      }
      return _decode(decoded);
    }

    final legacyMode = preferences.getString(_legacyModeKey);
    if (legacyMode == null) {
      return const ThemePreferences();
    }
    final mode = ThemeMode.values.where((item) => item.name == legacyMode);
    if (mode.isEmpty) {
      throw const FormatException('Pengaturan tema tersimpan tidak valid.');
    }
    return ThemePreferences(
      mode: switch (mode.first) {
        ThemeMode.system => ThemeModeChoice.system,
        ThemeMode.light => ThemeModeChoice.light,
        ThemeMode.dark => ThemeModeChoice.dark,
      },
    );
  }

  Future<void> setMode(ThemeModeChoice mode) =>
      _update((current) => current.copyWith(mode: mode));

  Future<void> setColorStyle(ThemeColorStyle style) =>
      _update((current) => current.copyWith(colorStyle: style));

  Future<void> setCustomSeed(int seed) =>
      _update((current) => current.copyWith(customSeed: seed));

  Future<void> setEarthAnimationsEnabled(bool enabled) =>
      _update((current) => current.copyWith(earthAnimationsEnabled: enabled));

  Future<void> _update(
    ThemePreferences Function(ThemePreferences current) change,
  ) async {
    final previous = state.asData?.value ?? await future;
    final updated = change(previous);
    state = AsyncData(updated);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode({
          'mode': updated.mode.name,
          'colorStyle': updated.colorStyle.name,
          'customSeed': updated.customSeed,
          'earthAnimationsEnabled': updated.earthAnimationsEnabled,
        }),
      );
      if (!saved) {
        throw const ThemeControllerException(
          'Pengaturan tampilan tidak dapat disimpan.',
        );
      }
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  ThemePreferences _decode(Map<String, dynamic> json) {
    final mode = ThemeModeChoice.values
        .where((item) => item.name == json['mode'])
        .firstOrNull;
    final colorStyle = ThemeColorStyle.values
        .where((item) => item.name == json['colorStyle'])
        .firstOrNull;
    if (mode == null ||
        colorStyle == null ||
        json['customSeed'] is! int ||
        json['earthAnimationsEnabled'] is! bool) {
      throw const FormatException('Pengaturan tampilan tersimpan tidak valid.');
    }
    return ThemePreferences(
      mode: mode,
      colorStyle: colorStyle,
      customSeed: json['customSeed'] as int,
      earthAnimationsEnabled: json['earthAnimationsEnabled'] as bool,
    );
  }
}

class ThemeControllerException implements Exception {
  const ThemeControllerException(this.message);

  final String message;

  @override
  String toString() => message;
}
