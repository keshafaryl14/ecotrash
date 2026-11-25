import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/router/app_router.dart';
import 'package:ecotrash/core/theme/app_theme.dart';
import 'package:ecotrash/core/theme/color_schemes.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcoTrashApp extends ConsumerWidget {
  const EcoTrashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences =
        ref.watch(themeControllerProvider).asData?.value ??
        const ThemePreferences();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = AppColorSchemes.resolve(
          brightness: Brightness.light,
          style: preferences.colorStyle,
          dynamicScheme: lightDynamic,
          customSeed: preferences.customSeed,
        );
        final darkScheme = AppColorSchemes.resolve(
          brightness: Brightness.dark,
          style: preferences.colorStyle,
          dynamicScheme: darkDynamic,
          customSeed: preferences.customSeed,
        );
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme, amoled: preferences.amoled),
          themeMode: preferences.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeOutCubic,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('id'), Locale('en')],
          routerConfig: router,
        );
      },
    );
  }
}
