import 'dart:async';

import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/router/app_router.dart';
import 'package:ecotrash/core/theme/app_theme.dart';
import 'package:ecotrash/core/theme/color_schemes.dart';
import 'package:ecotrash/core/theme/theme_controller.dart';
import 'package:ecotrash/core/widgets/eco_logo.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcoTrashApp extends ConsumerStatefulWidget {
  const EcoTrashApp({super.key});

  @override
  ConsumerState<EcoTrashApp> createState() => _EcoTrashAppState();
}

class _EcoTrashAppState extends ConsumerState<EcoTrashApp> {
  Timer? _fadeSplashTimer;
  Timer? _dismissSplashTimer;
  var _showSplash = true;
  var _fadeSplash = false;

  @override
  void initState() {
    super.initState();
    _fadeSplashTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() => _fadeSplash = true);
      }
    });
    _dismissSplashTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _fadeSplashTimer?.cancel();
    _dismissSplashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          builder: (context, child) {
            final systemIsDark =
                MediaQuery.platformBrightnessOf(context) == Brightness.dark;
            final isDark = switch (preferences.themeMode) {
              ThemeMode.dark => true,
              ThemeMode.light => false,
              ThemeMode.system => systemIsDark,
            };
            final showSplash =
                _showSplash && !MediaQuery.disableAnimationsOf(context);

            return Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  excluding: showSplash,
                  child: child ?? const SizedBox.expand(),
                ),
                if (showSplash)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _fadeSplash ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: AbsorbPointer(
                        child: Theme(
                          data: isDark
                              ? AppTheme.dark(
                                  darkScheme,
                                  amoled: preferences.amoled,
                                )
                              : AppTheme.light(lightScheme),
                          child: _BrandingSplash(isDark: isDark),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BrandingSplash extends StatelessWidget {
  const _BrandingSplash({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) => Material(
    color: isDark ? const Color(0xFF101712) : const Color(0xFFF6FBF4),
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.9 + (value * 0.1), child: child),
        ),
        child: const EcoLogo(size: 168, variant: EcoLogoVariant.icon),
      ),
    ),
  );
}
