import 'package:ecotrash/core/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores the selected theme mode across provider containers', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(themeModeProvider.future), ThemeMode.system);

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    expect(await container.read(themeModeProvider.future), ThemeMode.dark);

    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    expect(
      await restoredContainer.read(themeModeProvider.future),
      ThemeMode.dark,
    );
  });
}
