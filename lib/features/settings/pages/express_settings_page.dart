import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_switch.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/settings/pages/about_page.dart';
import 'package:streak/features/settings/pages/app_style_page.dart';
import 'package:streak/features/settings/pages/archived_habits_page.dart';
import 'package:streak/features/settings/pages/quotes_page.dart';
import 'package:streak/features/settings/settings_actions.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/settings/widgets/settings_sheets.dart';

class ExpressSettingsPage extends StatelessWidget {
  const ExpressSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    final items = <Widget>[
      ExpressHeadline(title: context.l10n.settings),
      const SizedBox(height: 20),
      const _ProfileHero(),
      const SizedBox(height: 10),
      ExpressGroup(
        children: [
          ExpressTile(
            icon: LucideIcons.smartphone,
            title: context.l10n.app_style,
            value: switch (settings.appStyle) {
              1 => context.l10n.style_minimal,
              2 => context.l10n.style_express,
              _ => context.l10n.style_classic,
            },
            onTap: () => AppNavigator.push(const AppStylePage()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SectionTile(
                icon: LucideIcons.palette,
                title: context.l10n.appearance,
                subtitle: context.l10n.appearance_sub,
                onTap: () => AppNavigator.push(const _AppearancePage()),
              ),
            ),
            const SizedBox(width: Express.groupGap),
            Expanded(
              child: _SectionTile(
                icon: LucideIcons.slidersHorizontal,
                title: context.l10n.preferences,
                subtitle: context.l10n.preferences_sub,
                onTap: () => AppNavigator.push(const _PreferencesPage()),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: Express.groupGap),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SectionTile(
                icon: LucideIcons.database,
                title: context.l10n.data,
                subtitle: context.l10n.data_sub,
                onTap: () => AppNavigator.push(const _DataPage()),
              ),
            ),
            const SizedBox(width: Express.groupGap),
            Expanded(
              child: _SectionTile(
                icon: LucideIcons.heartHandshake,
                title: context.l10n.support,
                subtitle: context.l10n.support_sub,
                onTap: () => AppNavigator.push(const _SupportPage()),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      ExpressGroup(
        children: [
          ExpressTile(
            icon: LucideIcons.info,
            title: context.l10n.about_app,
            subtitle: context.l10n.about_app_sub,
            onTap: () => AppNavigator.push(const AboutPage()),
          ),
        ],
      ),
      const SizedBox(height: 44),
      const _Footer(),
    ];

    return Scaffold(
      appBar: AppBar(toolbarHeight: 52),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: context.pagePadding(18, 0, 18, 128),
            children: [
              for (var i = 0; i < items.length; i++)
                ExpressReveal(index: i, child: items[i]),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;

    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 16, 20),
        decoration: BoxDecoration(
          color: expressSurface(context),
          borderRadius: BorderRadius.circular(Express.heroRadius),
          border: expressHairline(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpressBlob(
              size: 46,
              color: accent.withValues(alpha: 0.16),
              shape: ExpressShape.cookie,
              child: Icon(icon, size: 21, color: accent),
            ),
            const SizedBox(height: 18),
            const Spacer(),
            Text(
              title,
              style: ExpressType.headline.at(
                17,
                height: 1.1,
                weight: 800,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: ExpressType.body.at(
                12,
                height: 1.35,
                color: context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context) => ExpressScaffold(
    title: context.l10n.appearance,
    subtitle: context.l10n.appearance_sub,
    children: _appearanceTiles(context),
  );
}

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage();

  @override
  Widget build(BuildContext context) => ExpressScaffold(
    title: context.l10n.preferences,
    subtitle: context.l10n.preferences_sub,
    children: _preferenceTiles(context),
  );
}

class _DataPage extends StatelessWidget {
  const _DataPage();

  @override
  Widget build(BuildContext context) => ExpressScaffold(
    title: context.l10n.data,
    subtitle: context.l10n.data_sub,
    children: _dataTiles(context),
  );
}

class _SupportPage extends StatelessWidget {
  const _SupportPage();

  @override
  Widget build(BuildContext context) => ExpressScaffold(
    title: context.l10n.support,
    subtitle: context.l10n.support_sub,
    children: _supportTiles(context),
  );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final name = settings.profileName.isEmpty
        ? context.l10n.default_user
        : settings.profileName;
    final filePath = settings.profilePhoto.split('?').first;
    final hasPhoto = filePath.isNotEmpty && File(filePath).existsSync();

    return ExpressCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.l10n.change_photo,
            child: GestureDetector(
              onTap: () => SettingsActions.pickProfilePhoto(context),
              child: SizedBox(
                width: 72,
                height: 72,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const ExpressBorder(shape: ExpressShape.cookie),
                    image: DecorationImage(
                      image: hasPhoto
                          ? FileImage(File(filePath)) as ImageProvider
                          : const AssetImage('assets/profile_default.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              button: true,
              label: context.l10n.edit_name,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => SettingsActions.editName(context),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ExpressType.display.at(
                          26,
                          height: 1.1,
                          spacing: -0.4,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(
                      LucideIcons.pencil,
                      size: 15,
                      color: context.tokens.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tile = ExpressTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: ExpressSwitch(value: value, onChanged: onChanged),
    );
    if (enabled) return tile;
    return IgnorePointer(child: Opacity(opacity: 0.45, child: tile));
  }
}

List<Widget> _appearanceTiles(BuildContext context) {
  final settings = context.watch<SettingsController>();
  final themes = [
    context.l10n.system,
    context.l10n.light,
    context.l10n.dark,
  ];
  final checks = [context.l10n.square, context.l10n.circle];
  final icons = [
    context.l10n.icon_default,
    context.l10n.icon_neutral,
    context.l10n.icon_accent,
  ];

  return [
    ExpressGroup(
      children: [
        ExpressTile(
          icon: LucideIcons.sunMoon,
          title: context.l10n.theme,
          subtitle: context.l10n.theme_sub,
          value: themes[settings.themeMode.index],
          onTap: () => showOptionSheet(
            context,
            title: context.l10n.theme,
            options: themes,
            index: settings.themeMode.index,
            onSelected: (i) => settings.setThemeMode(ThemeMode.values[i]),
          ),
        ),
        ExpressTile(
          icon: LucideIcons.palette,
          title: context.l10n.accent_color,
          subtitle: context.l10n.accent_color_sub,
          trailing: ExpressBlob(
            size: 26,
            color: settings.accentColor,
            shape: ExpressShape.cookie,
          ),
          onTap: () => showAccentSheet(context),
        ),
        ExpressTile(
          icon: LucideIcons.image,
          title: context.l10n.app_background,
          subtitle: context.l10n.app_background_sub,
          value: SettingsActions.backgroundLabel(
            context,
            settings.appBackground,
          ),
          onTap: () => showBackgroundSheet(context),
        ),
        ExpressTile(
          icon: LucideIcons.squareCheck,
          title: context.l10n.check_style,
          subtitle: context.l10n.check_style_sub,
          value: checks[settings.checkStyle],
          onTap: () => showOptionSheet(
            context,
            title: context.l10n.check_style,
            options: checks,
            index: settings.checkStyle,
            onSelected: settings.setCheckStyle,
          ),
        ),
        if (hasAppIcons)
          ExpressTile(
            icon: LucideIcons.appWindow,
            title: context.l10n.app_icon,
            subtitle: context.l10n.app_icon_sub,
            value: icons[settings.appIcon],
            onTap: () => showOptionSheet(
              context,
              title: context.l10n.app_icon,
              options: icons,
              index: settings.appIcon,
              onSelected: settings.setAppIcon,
            ),
          ),
      ],
    ),
  ];
}

List<Widget> _preferenceTiles(BuildContext context) {
  final settings = context.watch<SettingsController>();
  final weekIndex = switch (settings.weekStart) {
    6 => 1,
    7 => 2,
    _ => 0,
  };
  final weekDays = [context.l10n.mon, context.l10n.sat, context.l10n.sun];

  return [
    SectionLabel(context.l10n.prefs_general),
    ExpressGroup(
      children: [
        ExpressTile(
          icon: LucideIcons.languages,
          title: context.l10n.language,
          subtitle: context.l10n.language_sub,
          value: SettingsActions.languageLabel(context, settings.localeCode),
          onTap: () => showLanguageSheet(context),
        ),
        ExpressTile(
          icon: LucideIcons.calendarDays,
          title: context.l10n.week_starts_on,
          subtitle: context.l10n.week_start_sub,
          value: weekDays[weekIndex],
          onTap: () => showOptionSheet(
            context,
            title: context.l10n.week_starts_on,
            options: weekDays,
            index: weekIndex,
            onSelected: (i) => settings.setWeekStart(
              switch (i) {
                1 => 6,
                2 => 7,
                _ => 1,
              },
            ),
          ),
        ),
        ExpressTile(
          icon: LucideIcons.moon,
          title: context.l10n.day_start,
          subtitle: context.l10n.day_start_sub,
          value: SettingsActions.dayStartLabels(context)[settings.dayCutoff],
          onTap: () => showOptionSheet(
            context,
            title: context.l10n.day_start,
            options: SettingsActions.dayStartLabels(context),
            index: settings.dayCutoff,
            onSelected: settings.setDayCutoff,
          ),
        ),
        ExpressTile(
          icon: LucideIcons.sparkles,
          title: context.l10n.celebration,
          subtitle: context.l10n.celebration_sub,
          value: SettingsActions.celebrationLabels(
            context,
          )[settings.celebration.index],
          onTap: () => showOptionSheet(
            context,
            title: context.l10n.celebration,
            options: SettingsActions.celebrationLabels(context),
            index: settings.celebration.index,
            onSelected: settings.setCelebration,
          ),
        ),
      ],
    ),
    const SizedBox(height: 24),
    SectionLabel(context.l10n.today),
    ExpressGroup(
      children: [
        ExpressTile(
          icon: LucideIcons.house,
          title: context.l10n.start_view,
          subtitle: context.l10n.start_view_sub,
          value: SettingsActions.startViewLabels(context)[settings.startView],
          onTap: () => showOptionSheet(
            context,
            title: context.l10n.start_view,
            options: SettingsActions.startViewLabels(context),
            index: settings.startView,
            onSelected: settings.setStartView,
          ),
        ),
        _Toggle(
          icon: LucideIcons.layoutGrid,
          title: context.l10n.card_activity,
          subtitle: context.l10n.card_activity_sub,
          value: settings.cardActivity,
          onChanged: settings.setCardActivity,
        ),
        _Toggle(
          icon: LucideIcons.layoutList,
          title: context.l10n.view_switcher,
          subtitle: settings.cardActivity
              ? context.l10n.view_switcher_sub
              : context.l10n.view_switcher_needs,
          enabled: settings.cardActivity,
          value: settings.viewSwitcher,
          onChanged: settings.setViewSwitcher,
        ),
        _Toggle(
          icon: LucideIcons.arrowDownWideNarrow,
          title: context.l10n.sort_completed_last,
          subtitle: context.l10n.sort_completed_last_sub,
          value: settings.sortCompletedLast,
          onChanged: settings.setSortCompletedLast,
        ),
        _Toggle(
          icon: LucideIcons.palmtree,
          title: context.l10n.vacation_all,
          subtitle: context.l10n.vacation_all_sub,
          value: settings.vacationAll,
          onChanged: (on) => SettingsActions.setVacationAll(context, on),
        ),
        _Toggle(
          icon: LucideIcons.calendarCheck,
          title: context.l10n.today_only,
          subtitle: context.l10n.today_only_sub,
          value: settings.todayOnly,
          onChanged: settings.setTodayOnly,
        ),
      ],
    ),
    const SizedBox(height: 24),
    SectionLabel(context.l10n.prefs_features),
    ExpressGroup(
      children: [
        _Toggle(
          icon: LucideIcons.timer,
          title: context.l10n.focus,
          subtitle: context.l10n.focus_enable_sub,
          value: settings.focusEnabled,
          onChanged: settings.setFocusEnabled,
        ),
        if (settings.focusEnabled)
          ExpressTile(
            icon: LucideIcons.target,
            title: context.l10n.focus_daily_goal,
            subtitle: context.l10n.focus_daily_goal_sub,
            value: settings.focusDailyGoal == 0
                ? context.l10n.off
                : context.l10n.minutes_short('${settings.focusDailyGoal}'),
            onTap: () async {
              final value = await showNumberKeypadDialog(
                context,
                title: context.l10n.focus_daily_goal,
                value: settings.focusDailyGoal.toDouble(),
                unit: context.l10n.unit_min_short,
                min: 0,
              );
              if (value != null) settings.setFocusDailyGoal(value.round());
            },
          ),
        _Toggle(
          icon: LucideIcons.notebookPen,
          title: context.l10n.notes,
          subtitle: context.l10n.notes_enable_sub,
          value: settings.notesEnabled,
          onChanged: settings.setNotesEnabled,
        ),
        _Toggle(
          icon: LucideIcons.listChecks,
          title: context.l10n.todos,
          subtitle: context.l10n.todos_enable_sub,
          value: settings.todosEnabled,
          onChanged: settings.setTodosEnabled,
        ),
        _Toggle(
          icon: LucideIcons.calendarClock,
          title: context.l10n.plan_day,
          subtitle: context.l10n.plan_day_sub,
          value: settings.planningEnabled,
          onChanged: settings.setPlanningEnabled,
        ),
        _Toggle(
          icon: LucideIcons.activity,
          title: context.l10n.just_tracking_option,
          subtitle: context.l10n.just_tracking_option_sub,
          value: settings.trackingOption,
          onChanged: settings.setTrackingOption,
        ),
        ExpressTile(
          icon: LucideIcons.quote,
          title: context.l10n.quotes,
          subtitle: context.l10n.quotes_sub,
          onTap: () => AppNavigator.push(const QuotesPage()),
        ),
      ],
    ),
    const SizedBox(height: 24),
    SectionLabel(context.l10n.prefs_privacy),
    ExpressGroup(
      children: [
        _Toggle(
          icon: LucideIcons.fingerprint,
          title: context.l10n.app_lock,
          subtitle: context.l10n.app_lock_sub,
          value: settings.appLock,
          onChanged: (v) => SettingsActions.toggleAppLock(context, v),
        ),
        if (settings.appLock)
          ExpressTile(
            icon: LucideIcons.timer,
            title: context.l10n.app_lock_delay,
            subtitle: context.l10n.app_lock_delay_sub,
            value: SettingsActions.appLockDelayLabels(
              context,
            )[SettingsActions.appLockDelayIndex(settings.appLockDelay)],
            onTap: () => showOptionSheet(
              context,
              title: context.l10n.app_lock_delay,
              options: SettingsActions.appLockDelayLabels(context),
              index: SettingsActions.appLockDelayIndex(settings.appLockDelay),
              onSelected: (i) => settings.setAppLockDelay(
                SettingsActions.appLockDelays[i],
              ),
            ),
          ),
      ],
    ),
  ];
}

List<Widget> _dataTiles(BuildContext context) {
  return [
    ExpressGroup(
      children: [
        ExpressTile(
          icon: LucideIcons.import,
          title: context.l10n.import_from_app,
          subtitle: context.l10n.import_from_app_sub,
          onTap: () => SettingsActions.importFromApp(context),
        ),
        ExpressTile(
          icon: LucideIcons.upload,
          title: context.l10n.import_backup,
          subtitle: context.l10n.import_backup_sub,
          onTap: () => SettingsActions.importBackup(context),
        ),
        ExpressTile(
          icon: LucideIcons.download,
          title: context.l10n.export_backup,
          subtitle: context.l10n.export_backup_sub,
          onTap: () => SettingsActions.exportBackup(context),
        ),
        ExpressTile(
          icon: LucideIcons.databaseBackup,
          title: context.l10n.auto_backup,
          subtitle: SettingsActions.autoBackupSubtitle(context),
          onTap: () => SettingsActions.pickAutoBackup(context),
        ),
        if (SettingsActions.canRefresh(context))
          ExpressTile(
            icon: LucideIcons.refreshCw,
            title: context.l10n.refresh_now,
            subtitle: context.l10n.refresh_now_sub,
            onTap: () => SettingsActions.refreshFolder(context),
          ),
        ExpressTile(
          icon: LucideIcons.archive,
          title: context.l10n.archived_habits,
          subtitle: context.l10n.archived_habits_sub,
          onTap: () => AppNavigator.push(const ArchivedHabitsPage()),
        ),
        ExpressTile(
          icon: LucideIcons.eraser,
          title: context.l10n.clear_progress,
          subtitle: context.l10n.clear_progress_sub,
          onTap: () => SettingsActions.clearProgress(context),
        ),
        ExpressTile(
          icon: LucideIcons.triangleAlert,
          title: context.l10n.wipe_data,
          subtitle: context.l10n.wipe_data_sub,
          tint: context.tokens.danger,
          onTap: () => SettingsActions.wipeEverything(context),
        ),
      ],
    ),
  ];
}

List<Widget> _supportTiles(BuildContext context) {
  return [
    ExpressGroup(
      children: [
        ExpressTile(
          icon: LucideIcons.userPlus,
          title: context.l10n.share_friends,
          subtitle: context.l10n.share_friends_sub,
          onTap: () => SettingsActions.shareWithFriend(context),
        ),
        ExpressTile(
          icon: LucideIcons.star,
          title: context.l10n.github_star_row,
          subtitle: context.l10n.github_star_sub,
          onTap: () => SettingsActions.openUrl(context, kGitHubUrl),
        ),
        ExpressTile(
          icon: LucideIcons.coffee,
          title: context.l10n.buy_coffee,
          subtitle: context.l10n.buy_coffee_sub,
          onTap: () => SettingsActions.openUrl(context, kCoffeeUrl),
        ),
        ExpressTile(
          icon: LucideIcons.messageSquare,
          title: context.l10n.report_issue,
          subtitle: context.l10n.report_issue_sub,
          onTap: () => SettingsActions.openUrl(context, '$kIssuesUrl/new'),
        ),
      ],
    ),
  ];
}

class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    return Column(
      children: [
        AnimatedContainer(
          duration: Express.slow,
          curve: Express.bouncy,
          width: 54,
          height: 54,
          decoration: ShapeDecoration(
            color: context.colors.primary.withValues(alpha: 0.14),
            shape: const ExpressBorder(shape: ExpressShape.flower),
          ),
          child: Icon(
            LucideIcons.flame,
            size: 22,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'STREAK $_version'.trim(),
          style: ExpressType.body.at(
            12,
            weight: 800,
            spacing: 2.4,
            color: muted.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
