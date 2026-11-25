import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists theme, palette and motion preferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      await container.read(themeControllerProvider.future),
      const ThemePreferences(),
    );

    final controller = container.read(themeControllerProvider.notifier);
    await controller.setMode(ThemeModeChoice.amoled);
    await controller.setColorStyle(ThemeColorStyle.custom);
    await controller.setCustomSeed(0xFF1565C0);
    await controller.setEarthAnimationsEnabled(false);

    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    expect(
      await restoredContainer.read(themeControllerProvider.future),
      const ThemePreferences(
        mode: ThemeModeChoice.amoled,
        colorStyle: ThemeColorStyle.custom,
        customSeed: 0xFF1565C0,
        earthAnimationsEnabled: false,
      ),
    );
  });
}
