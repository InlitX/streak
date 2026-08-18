import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/settings/pages/about_page.dart';
import 'package:streak/features/settings/pages/app_style_page.dart';
import 'package:streak/features/settings/pages/archived_habits_page.dart';
import 'package:streak/features/settings/pages/minimal_settings_page.dart';
import 'package:streak/features/settings/pages/quotes_page.dart';
import 'package:streak/features/settings/settings_actions.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/settings_rows.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/settings/widgets/settings_sheets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return context.watch<SettingsController>().isMinimalStyle
        ? const MinimalSettingsPage()
        : const ClassicSettingsPage();
  }
}

class ClassicSettingsPage extends StatelessWidget {
  const ClassicSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        padding: context.pagePadding(16, 16, 16, 104),
        children: [
          Entrance(
            child: _ProfileHeader(
              name: settings.profileName.isEmpty
                  ? context.l10n.default_user
                  : settings.profileName,
              photoPath: settings.profilePhoto,
            ),
          ),
          const SizedBox(height: 24),
          Entrance(
            index: 1,
            child: Card(
              child: PickerRow(
                icon: LucideIcons.smartphone,
                title: context.l10n.app_style,
                value: settings.isMinimalStyle
                    ? context.l10n.style_minimal
                    : context.l10n.style_classic,
                onTap: () => AppNavigator.push(const AppStylePage()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Entrance(
            index: 2,
            child: Card(
              child: Column(
                children: [
                  NavRow(
                    icon: LucideIcons.palette,
                    title: context.l10n.appearance,
                    subtitle: context.l10n.appearance_sub,
                    onTap: () =>
                        AppNavigator.push(const _ClassicAppearancePage()),
                  ),
                  settingsDivider(context),
                  NavRow(
                    icon: LucideIcons.slidersHorizontal,
                    title: context.l10n.preferences,
                    subtitle: context.l10n.preferences_sub,
                    onTap: () =>
                        AppNavigator.push(const _ClassicPreferencesPage()),
                  ),
                  settingsDivider(context),
                  NavRow(
                    icon: LucideIcons.database,
                    title: context.l10n.data,
                    subtitle: context.l10n.data_sub,
                    onTap: () => AppNavigator.push(const _ClassicDataPage()),
                  ),
                  settingsDivider(context),
                  NavRow(
                    icon: LucideIcons.heartHandshake,
                    title: context.l10n.support,
                    subtitle: context.l10n.support_sub,
                    onTap: () =>
                        AppNavigator.push(const _ClassicSupportPage()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Entrance(
            index: 3,
            child: Card(
              child: NavRow(
                icon: LucideIcons.info,
                title: context.l10n.about_app,
                subtitle: context.l10n.about_app_sub,
                onTap: () => AppNavigator.push(const AboutPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicSection extends StatelessWidget {
  const _ClassicSection({
    required this.title,
    required this.label,
    required this.children,
  });

  final String title;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: context.pagePadding(16, 8, 16, 24),
        children: [
          Entrance(child: SectionLabel(label)),
          Entrance(index: 1, child: Card(child: Column(children: children))),
        ],
      ),
    );
  }
}

class _ClassicAppearancePage extends StatelessWidget {
  const _ClassicAppearancePage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return _ClassicSection(
      title: context.l10n.appearance,
      label: context.l10n.appearance_sub,
      children: [
        SettingRow(
          icon: LucideIcons.sunMoon,
          title: context.l10n.theme,
          trailing: Segmented(
            options: [
              context.l10n.system,
              context.l10n.light,
              context.l10n.dark,
            ],
            index: settings.themeMode.index,
            onChanged: (i) => settings.setThemeMode(ThemeMode.values[i]),
          ),
        ),
        settingsDivider(context),
        PickerRow(
          icon: LucideIcons.palette,
          title: context.l10n.accent_color,
          value: null,
          trailing: _AccentDot(color: settings.accentColor),
          onTap: () => showAccentSheet(context),
        ),
        settingsDivider(context),
        PickerRow(
          icon: LucideIcons.image,
          title: context.l10n.app_background,
          value: SettingsActions.backgroundLabel(
            context,
            settings.appBackground,
          ),
          onTap: () => showBackgroundSheet(context),
        ),
        settingsDivider(context),
        SettingRow(
          icon: LucideIcons.squareCheck,
          title: context.l10n.check_style,
          trailing: Segmented(
            options: [context.l10n.square, context.l10n.circle],
            index: settings.checkStyle,
            onChanged: settings.setCheckStyle,
          ),
        ),
        settingsDivider(context),
        SettingRow(
          icon: LucideIcons.appWindow,
          title: context.l10n.app_icon,
          trailing: Segmented(
            options: [
              context.l10n.icon_default,
              context.l10n.icon_neutral,
              context.l10n.icon_accent,
            ],
            index: settings.appIcon,
            onChanged: settings.setAppIcon,
          ),
        ),
      ],
    );
  }
}

class _ClassicPreferencesPage extends StatelessWidget {
  const _ClassicPreferencesPage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.preferences)),
      body: ListView(
        padding: context.pagePadding(16, 8, 16, 24),
        children: [
          Entrance(child: SectionLabel(context.l10n.prefs_general)),
          Entrance(
            index: 1,
            child: Card(
              child: Column(
                children: [
                  PickerRow(
                    icon: LucideIcons.languages,
                    title: context.l10n.language,
                    value: SettingsActions.languageLabel(
                      context,
                      settings.localeCode,
                    ),
                    onTap: () => showLanguageSheet(context),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.calendarDays,
                    title: context.l10n.week_starts_on,
                    trailing: Segmented(
                      options: [
                        context.l10n.mon,
                        context.l10n.sat,
                        context.l10n.sun,
                      ],
                      index: switch (settings.weekStart) {
                        6 => 1,
                        7 => 2,
                        _ => 0,
                      },
                      onChanged: (i) => settings.setWeekStart(
                        switch (i) {
                          1 => 6,
                          2 => 7,
                          _ => 1,
                        },
                      ),
                    ),
                  ),
                  settingsDivider(context),
                  NavRow(
                    icon: LucideIcons.moon,
                    title: context.l10n.day_start,
                    subtitle: SettingsActions.dayStartLabels(
                      context,
                    )[settings.dayCutoff],
                    onTap: () => showOptionSheet(
                      context,
                      title: context.l10n.day_start,
                      options: SettingsActions.dayStartLabels(context),
                      index: settings.dayCutoff,
                      onSelected: settings.setDayCutoff,
                    ),
                  ),
                  settingsDivider(context),
                  NavRow(
                    icon: LucideIcons.sparkles,
                    title: context.l10n.celebration,
                    subtitle: SettingsActions.celebrationLabels(
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
            ),
          ),
          const SizedBox(height: 24),
          Entrance(index: 2, child: SectionLabel(context.l10n.today)),
          Entrance(
            index: 3,
            child: Card(
              child: Column(
                children: [
                  NavRow(
                    icon: LucideIcons.house,
                    title: context.l10n.start_view,
                    subtitle: SettingsActions.startViewLabels(
                      context,
                    )[settings.startView],
                    onTap: () => showOptionSheet(
                      context,
                      title: context.l10n.start_view,
                      options: SettingsActions.startViewLabels(context),
                      index: settings.startView,
                      onSelected: settings.setStartView,
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.layoutList,
                    title: context.l10n.view_switcher,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.viewSwitcher ? 1 : 0,
                      onChanged: (i) => settings.setViewSwitcher(i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.layoutGrid,
                    title: context.l10n.card_activity,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.cardActivity ? 1 : 0,
                      onChanged: (i) => settings.setCardActivity(i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.arrowDownWideNarrow,
                    title: context.l10n.sort_completed_last,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.sortCompletedLast ? 1 : 0,
                      onChanged: (i) => settings.setSortCompletedLast(i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.palmtree,
                    title: context.l10n.vacation_all,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.vacationAll ? 1 : 0,
                      onChanged: (i) => SettingsActions.setVacationAll(context, i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.calendarCheck,
                    title: context.l10n.today_only,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.todayOnly ? 1 : 0,
                      onChanged: (i) => settings.setTodayOnly(i == 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Entrance(index: 4, child: SectionLabel(context.l10n.prefs_features)),
          Entrance(
            index: 5,
            child: Card(
              child: Column(
                children: [
                  SettingRow(
                    icon: LucideIcons.timer,
                    title: context.l10n.focus,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.focusEnabled ? 1 : 0,
                      onChanged: (i) => settings.setFocusEnabled(i == 1),
                    ),
                  ),
                  if (settings.focusEnabled) ...[
                    settingsDivider(context),
                    PickerRow(
                      icon: LucideIcons.target,
                      title: context.l10n.focus_daily_goal,
                      value: settings.focusDailyGoal == 0
                          ? context.l10n.off
                          : context.l10n.minutes_short(
                              '${settings.focusDailyGoal}',
                            ),
                      onTap: () async {
                        final value = await showNumberKeypadDialog(
                          context,
                          title: context.l10n.focus_daily_goal,
                          value: settings.focusDailyGoal.toDouble(),
                          unit: context.l10n.unit_min_short,
                          min: 0,
                        );
                        if (value != null) {
                          settings.setFocusDailyGoal(value.round());
                        }
                      },
                    ),
                  ],
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.notebookPen,
                    title: context.l10n.notes,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.notesEnabled ? 1 : 0,
                      onChanged: (i) => settings.setNotesEnabled(i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.listChecks,
                    title: context.l10n.todos,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.todosEnabled ? 1 : 0,
                      onChanged: (i) => settings.setTodosEnabled(i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  SettingRow(
                    icon: LucideIcons.calendarClock,
                    title: context.l10n.plan_day,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.planningEnabled ? 1 : 0,
                      onChanged: (i) => settings.setPlanningEnabled(i == 1),
                    ),
                  ),
                  settingsDivider(context),
                  NavRow(
                    icon: LucideIcons.quote,
                    title: context.l10n.quotes,
                    onTap: () => AppNavigator.push(const QuotesPage()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Entrance(index: 6, child: SectionLabel(context.l10n.prefs_privacy)),
          Entrance(
            index: 7,
            child: Card(
              child: Column(
                children: [
                  SettingRow(
                    icon: LucideIcons.fingerprint,
                    title: context.l10n.app_lock,
                    trailing: Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.appLock ? 1 : 0,
                      onChanged: (i) =>
                          SettingsActions.toggleAppLock(context, i == 1),
                    ),
                  ),
                  if (settings.appLock) ...[
                    settingsDivider(context),
                    NavRow(
                      icon: LucideIcons.timer,
                      title: context.l10n.app_lock_delay,
                      subtitle: SettingsActions.appLockDelayLabels(context)[
                          SettingsActions.appLockDelayIndex(
                              settings.appLockDelay)],
                      onTap: () => showOptionSheet(
                        context,
                        title: context.l10n.app_lock_delay,
                        options: SettingsActions.appLockDelayLabels(context),
                        index: SettingsActions.appLockDelayIndex(
                          settings.appLockDelay,
                        ),
                        onSelected: (i) => settings.setAppLockDelay(
                          SettingsActions.appLockDelays[i],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicDataPage extends StatelessWidget {
  const _ClassicDataPage();

  @override
  Widget build(BuildContext context) {
    return _ClassicSection(
      title: context.l10n.data,
      label: context.l10n.data_sub,
      children: [
        NavRow(
          icon: LucideIcons.import,
          title: context.l10n.import_from_app,
          subtitle: context.l10n.import_from_app_sub,
          badge: 'Beta',
          onTap: () => SettingsActions.importFromApp(context),
        ),
        settingsDivider(context),
        NavRow(
          icon: LucideIcons.upload,
          title: context.l10n.import_backup,
          subtitle: context.l10n.import_backup_sub,
          onTap: () => SettingsActions.importBackup(context),
        ),
        settingsDivider(context),
        NavRow(
          icon: LucideIcons.download,
          title: context.l10n.export_backup,
          subtitle: context.l10n.export_backup_sub,
          onTap: () => SettingsActions.exportBackup(context),
        ),
        settingsDivider(context),
        NavRow(
          icon: LucideIcons.databaseBackup,
          title: context.l10n.auto_backup,
          subtitle: SettingsActions.autoBackupSubtitle(context),
          onTap: () => SettingsActions.pickAutoBackup(context),
        ),
        settingsDivider(context),
        NavRow(
          icon: LucideIcons.archive,
          title: context.l10n.archived_habits,
          subtitle: context.l10n.archived_habits_sub,
          onTap: () => AppNavigator.push(const ArchivedHabitsPage()),
        ),
        settingsDivider(context),
        NavRow(
          icon: LucideIcons.eraser,
          title: context.l10n.clear_progress,
          subtitle: context.l10n.clear_progress_sub,
          onTap: () => SettingsActions.clearProgress(context),
        ),
        settingsDivider(context),
        NavRow(
          icon: LucideIcons.triangleAlert,
          tint: context.tokens.danger,
          title: context.l10n.wipe_data,
          subtitle: context.l10n.wipe_data_sub,
          onTap: () => SettingsActions.wipeEverything(context),
        ),
      ],
    );
  }
}

class _ClassicSupportPage extends StatelessWidget {
  const _ClassicSupportPage();

  @override
  Widget build(BuildContext context) {
    return _ClassicSection(
      title: context.l10n.support,
      label: context.l10n.support_sub,
      children: [
        NavRow(
          icon: LucideIcons.userPlus,
          title: context.l10n.share_friends,
          subtitle: context.l10n.share_friends_sub,
          onTap: () => SettingsActions.shareWithFriend(context),
        ),
        settingsDivider(context),
        LinkRow(
          icon: LucideIcons.star,
          title: context.l10n.github_star_row,
          onTap: () => SettingsActions.openUrl(context, kGitHubUrl),
        ),
        settingsDivider(context),
        LinkRow(
          icon: LucideIcons.coffee,
          title: context.l10n.buy_coffee,
          onTap: () => SettingsActions.openUrl(context, kCoffeeUrl),
        ),
        settingsDivider(context),
        LinkRow(
          icon: LucideIcons.messageSquare,
          title: context.l10n.report_issue,
          onTap: () => SettingsActions.openUrl(context, '$kIssuesUrl/new'),
        ),
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.surface, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.photoPath});

  final String name;
  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final filePath = photoPath.split('?').first;
    final hasPhoto = filePath.isNotEmpty && File(filePath).existsSync();

    return Column(
      children: [
        Semantics(
          button: true,
          label: context.l10n.change_photo,
          child: GestureDetector(
            onTap: () => SettingsActions.pickProfilePhoto(context),
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest,
                    image: DecorationImage(
                      image: hasPhoto
                          ? FileImage(File(filePath)) as ImageProvider
                          : const AssetImage('assets/profile_default.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 12,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: context.l10n.edit_name,
          child: GestureDetector(
            onTap: () => SettingsActions.editName(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(LucideIcons.pencil, size: 15, color: context.tokens.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
