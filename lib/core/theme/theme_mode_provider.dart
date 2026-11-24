import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const _storageKey = 'eco_theme_mode';

  @override
  Future<ThemeMode> build() async {
    final preferences = await SharedPreferences.getInstance();
    final storedMode = preferences.getString(_storageKey);
    if (storedMode == null) {
      return ThemeMode.system;
    }
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == storedMode,
      orElse: () =>
          throw const FormatException('Pengaturan tema tersimpan tidak valid.'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(_storageKey, mode.name);
      if (!saved) {
        throw const ThemeModeException('Pengaturan tema tidak dapat disimpan.');
      }
      return mode;
    });
    state = result;
    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}

class ThemeModeException implements Exception {
  const ThemeModeException(this.message);

  final String message;

  @override
  String toString() => message;
}
