import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_background.dart';
import 'package:streak/app/home_shell.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/onboarding/pages/onboarding_page.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class StreakApp extends StatelessWidget {
  const StreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Streak',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light(settings.accentColor),
      darkTheme: AppTheme.dark(settings.accentColor),
      themeMode: settings.themeMode,
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: settings.onboardingDone
          ? const HomeShell()
          : const OnboardingPage(),
    );
  }
}
