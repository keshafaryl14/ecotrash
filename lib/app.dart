import 'package:ecotrash/core/constants/app_constants.dart';
import 'package:ecotrash/core/router/app_router.dart';
import 'package:ecotrash/core/theme/app_theme.dart';
import 'package:ecotrash/core/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcoTrashApp extends ConsumerWidget {
  const EcoTrashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider).asData?.value;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode ?? ThemeMode.system,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('id'), Locale('en')],
      routerConfig: router,
    );
  }
}
