import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_background.dart';
import 'package:streak/app/app_lock.dart';
import 'package:streak/app/home_shell.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/onboarding/pages/onboarding_page.dart';
import 'package:streak/features/settings/settings_actions.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/home_widget_service.dart';

class StreakApp extends StatelessWidget {
  const StreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Streak',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light(settings.accentColor, settings.appStyle),
      darkTheme: AppTheme.dark(settings.accentColor, settings.appStyle),
      themeMode: settings.themeMode,
      builder: (context, child) {
        HomeWidgetService.localize(
          AppLocalizations.of(context),
          context.read<HabitsController>().asMap,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemBars(Theme.of(context).brightness),
          child: AppLockGate(
            child: AppBackground(
              child: _DesktopFrame(
                shell: settings.onboardingDone,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      locale: settings.locale,
      supportedLocales: SettingsActions.shippedLocales,
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

class _DesktopFrame extends StatelessWidget {
  const _DesktopFrame({required this.shell, required this.child});

  final bool shell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isMobile || (shell && isWideLayout(context))) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: phoneWidth),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
