import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/settings/pages/about_page.dart';
import 'package:streak/features/settings/pages/app_style_page.dart';
import 'package:streak/features/settings/pages/archived_habits_page.dart';
import 'package:streak/features/settings/settings_actions.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/settings/widgets/settings_sheets.dart';

class MinimalSettingsPage extends StatelessWidget {
  const MinimalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(toolbarHeight: 52),
      body: ListView(
        padding: context.pagePadding(22, 0, 22, 40),
        children: [
          _ProfileRow(
            name: settings.profileName.isEmpty
                ? context.l10n.default_user
                : settings.profileName,
            photoPath: settings.profilePhoto,
          ),
          const SizedBox(height: 28),
          SoftCard(
            children: [
              SoftRow(
                icon: LucideIcons.smartphone,
                title: context.l10n.app_style,
                value: settings.isMinimalStyle
                    ? context.l10n.style_minimal
                    : context.l10n.style_classic,
                onTap: () => AppNavigator.push(const AppStylePage()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SoftCard(
            children: [
              SoftRow(
                icon: LucideIcons.palette,
                title: context.l10n.appearance,
                subtitle: context.l10n.appearance_sub,
                onTap: () => AppNavigator.push(const _AppearancePage()),
              ),
              SoftRow(
                icon: LucideIcons.slidersHorizontal,
                title: context.l10n.preferences,
                subtitle: context.l10n.preferences_sub,
                onTap: () => AppNavigator.push(const _PreferencesPage()),
              ),
              SoftRow(
                icon: LucideIcons.database,
                title: context.l10n.data,
                subtitle: context.l10n.data_sub,
                onTap: () => AppNavigator.push(const _DataPage()),
              ),
              SoftRow(
                icon: LucideIcons.heartHandshake,
                title: context.l10n.support,
                subtitle: context.l10n.support_sub,
                onTap: () => AppNavigator.push(const _SupportPage()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SoftCard(
            children: [
              SoftRow(
                icon: LucideIcons.info,
                title: context.l10n.about_app,
                subtitle: context.l10n.about_app_sub,
                onTap: () => AppNavigator.push(const AboutPage()),
              ),
            ],
          ),
          const SizedBox(height: 64),
          const _Footer(),
        ],
      ),
    );
  }
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
        Text(
          'STREAK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.2,
            color: muted.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.about_footer,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: muted.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _version,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
            color: muted.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.name, required this.photoPath});

  final String name;
  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final filePath = photoPath.split('?').first;
    final hasPhoto = filePath.isNotEmpty && File(filePath).existsSync();

    return Row(
      children: [
        Semantics(
          button: true,
          label: context.l10n.change_photo,
          child: GestureDetector(
            onTap: () => SettingsActions.pickProfilePhoto(context),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.surfaceContainerHighest,
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
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            button: true,
            label: context.l10n.edit_name,
            child: GestureDetector(
              onTap: () => SettingsActions.editName(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.6,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Icon(LucideIcons.pencil, size: 14, color: context.tokens.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MinimalPage(
      title: context.l10n.appearance,
      subtitle: context.l10n.appearance_sub,
      children: [
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.sunMoon,
              title: context.l10n.theme,
              value: [
                context.l10n.system,
                context.l10n.light,
                context.l10n.dark,
              ][settings.themeMode.index],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.theme,
                options: [
                  context.l10n.system,
                  context.l10n.light,
                  context.l10n.dark,
                ],
                index: settings.themeMode.index,
                onSelected: (i) => settings.setThemeMode(ThemeMode.values[i]),
              ),
            ),
            SoftRow(
              icon: LucideIcons.palette,
              title: context.l10n.accent_color,
              trailing: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: settings.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              onTap: () => showAccentSheet(context),
            ),
            SoftRow(
              icon: LucideIcons.image,
              title: context.l10n.app_background,
              value: SettingsActions.backgroundLabel(
                context,
                settings.appBackground,
              ),
              onTap: () => showBackgroundSheet(context),
            ),
            SoftRow(
              icon: LucideIcons.squareCheck,
              title: context.l10n.check_style,
              value: [
                context.l10n.square,
                context.l10n.circle,
              ][settings.checkStyle],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.check_style,
                options: [context.l10n.square, context.l10n.circle],
                index: settings.checkStyle,
                onSelected: settings.setCheckStyle,
              ),
            ),
            SoftRow(
              icon: LucideIcons.appWindow,
              title: context.l10n.app_icon,
              value: [
                context.l10n.icon_default,
                context.l10n.icon_neutral,
                context.l10n.icon_accent,
              ][settings.appIcon],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.app_icon,
                options: [
                  context.l10n.icon_default,
                  context.l10n.icon_neutral,
                  context.l10n.icon_accent,
                ],
                index: settings.appIcon,
                onSelected: settings.setAppIcon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final weekIndex = switch (settings.weekStart) { 6 => 1, 7 => 2, _ => 0 };

    return MinimalPage(
      title: context.l10n.preferences,
      subtitle: context.l10n.preferences_sub,
      children: [
        SectionLabel(context.l10n.prefs_general),
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.languages,
              title: context.l10n.language,
              value: SettingsActions.languageLabel(context, settings.localeCode),
              onTap: () => showLanguageSheet(context),
            ),
            SoftRow(
              icon: LucideIcons.calendarDays,
              title: context.l10n.week_starts_on,
              value: [
                context.l10n.mon,
                context.l10n.sat,
                context.l10n.sun,
              ][weekIndex],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.week_starts_on,
                options: [
                  context.l10n.mon,
                  context.l10n.sat,
                  context.l10n.sun,
                ],
                index: weekIndex,
                onSelected: (i) => settings.setWeekStart(
                  switch (i) { 1 => 6, 2 => 7, _ => 1 },
                ),
              ),
            ),
            SoftRow(
              icon: LucideIcons.moon,
              title: context.l10n.day_start,
              value: SettingsActions.dayStartLabels(context)[settings.dayCutoff],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.day_start,
                options: SettingsActions.dayStartLabels(context),
                index: settings.dayCutoff,
                onSelected: settings.setDayCutoff,
              ),
            ),
            SoftRow(
              icon: LucideIcons.sparkles,
              title: context.l10n.celebration,
              value: SettingsActions.celebrationLabels(context)[
                  settings.celebration.index],
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
        const SizedBox(height: 22),
        SectionLabel(context.l10n.today),
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.house,
              title: context.l10n.start_view,
              value:
                  SettingsActions.startViewLabels(context)[settings.startView],
              onTap: () => showOptionSheet(
                context,
                title: context.l10n.start_view,
                options: SettingsActions.startViewLabels(context),
                index: settings.startView,
                onSelected: settings.setStartView,
              ),
            ),
            SoftRow(
              icon: LucideIcons.layoutList,
              title: context.l10n.view_switcher,
              subtitle: context.l10n.view_switcher_sub,
              trailing: _SoftSwitch(
                value: settings.viewSwitcher,
                onChanged: settings.setViewSwitcher,
              ),
            ),
            SoftRow(
              icon: LucideIcons.route,
              title: context.l10n.heatmap_path,
              subtitle: context.l10n.heatmap_path_sub,
              trailing: _SoftSwitch(
                value: settings.heatmapPath,
                onChanged: settings.setHeatmapPath,
              ),
            ),
            SoftRow(
              icon: LucideIcons.arrowDownWideNarrow,
              title: context.l10n.sort_completed_last,
              trailing: _SoftSwitch(
                value: settings.sortCompletedLast,
                onChanged: settings.setSortCompletedLast,
              ),
            ),
            SoftRow(
              icon: LucideIcons.palmtree,
              title: context.l10n.vacation_all,
              subtitle: context.l10n.vacation_all_sub,
              trailing: _SoftSwitch(
                value: settings.vacationAll,
                onChanged: (on) => SettingsActions.setVacationAll(context, on),
              ),
            ),
            SoftRow(
              icon: LucideIcons.calendarCheck,
              title: context.l10n.today_only,
              trailing: _SoftSwitch(
                value: settings.todayOnly,
                onChanged: settings.setTodayOnly,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionLabel(context.l10n.prefs_features),
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.timer,
              title: context.l10n.focus,
              subtitle: context.l10n.focus_enable_sub,
              trailing: _SoftSwitch(
                value: settings.focusEnabled,
                onChanged: settings.setFocusEnabled,
              ),
            ),
            SoftRow(
              icon: LucideIcons.notebookPen,
              title: context.l10n.notes,
              subtitle: context.l10n.notes_enable_sub,
              trailing: _SoftSwitch(
                value: settings.notesEnabled,
                onChanged: settings.setNotesEnabled,
              ),
            ),
            SoftRow(
              icon: LucideIcons.listChecks,
              title: context.l10n.todos,
              subtitle: context.l10n.todos_enable_sub,
              trailing: _SoftSwitch(
                value: settings.todosEnabled,
                onChanged: settings.setTodosEnabled,
              ),
            ),
            SoftRow(
              icon: LucideIcons.calendarClock,
              title: context.l10n.plan_day,
              subtitle: context.l10n.plan_day_sub,
              trailing: _SoftSwitch(
                value: settings.planningEnabled,
                onChanged: settings.setPlanningEnabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionLabel(context.l10n.prefs_privacy),
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.fingerprint,
              title: context.l10n.app_lock,
              trailing: _SoftSwitch(
                value: settings.appLock,
                onChanged: (v) => SettingsActions.toggleAppLock(context, v),
              ),
            ),
            if (settings.appLock)
              SoftRow(
                icon: LucideIcons.timer,
                title: context.l10n.app_lock_delay,
                value: SettingsActions.appLockDelayLabels(context)[
                    SettingsActions.appLockDelayIndex(settings.appLockDelay)],
                onTap: () => showOptionSheet(
                  context,
                  title: context.l10n.app_lock_delay,
                  options: SettingsActions.appLockDelayLabels(context),
                  index: SettingsActions.appLockDelayIndex(settings.appLockDelay),
                  onSelected: (i) =>
                      settings.setAppLockDelay(SettingsActions.appLockDelays[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SoftSwitch extends StatelessWidget {
  const _SoftSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.82,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _DataPage extends StatelessWidget {
  const _DataPage();

  @override
  Widget build(BuildContext context) {
    return MinimalPage(
      title: context.l10n.data,
      subtitle: context.l10n.data_sub,
      children: [
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.import,
              title: context.l10n.import_from_app,
              subtitle: context.l10n.import_from_app_sub,
              onTap: () => SettingsActions.importFromApp(context),
            ),
            SoftRow(
              icon: LucideIcons.upload,
              title: context.l10n.import_backup,
              subtitle: context.l10n.import_backup_sub,
              onTap: () => SettingsActions.importBackup(context),
            ),
            SoftRow(
              icon: LucideIcons.download,
              title: context.l10n.export_backup,
              subtitle: context.l10n.export_backup_sub,
              onTap: () => SettingsActions.exportBackup(context),
            ),
            SoftRow(
              icon: LucideIcons.databaseBackup,
              title: context.l10n.auto_backup,
              subtitle: SettingsActions.autoBackupSubtitle(context),
              onTap: () => SettingsActions.pickAutoBackup(context),
            ),
            SoftRow(
              icon: LucideIcons.archive,
              title: context.l10n.archived_habits,
              subtitle: context.l10n.archived_habits_sub,
              onTap: () => AppNavigator.push(const ArchivedHabitsPage()),
            ),
            SoftRow(
              icon: LucideIcons.eraser,
              title: context.l10n.clear_progress,
              subtitle: context.l10n.clear_progress_sub,
              onTap: () => SettingsActions.clearProgress(context),
            ),
            SoftRow(
              icon: LucideIcons.triangleAlert,
              title: context.l10n.wipe_data,
              subtitle: context.l10n.wipe_data_sub,
              onTap: () => SettingsActions.wipeEverything(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _SupportPage extends StatelessWidget {
  const _SupportPage();

  @override
  Widget build(BuildContext context) {
    return MinimalPage(
      title: context.l10n.support,
      subtitle: context.l10n.support_sub,
      children: [
        SoftCard(
          children: [
            SoftRow(
              icon: LucideIcons.userPlus,
              title: context.l10n.share_friends,
              subtitle: context.l10n.share_friends_sub,
              onTap: () => SettingsActions.shareWithFriend(context),
            ),
            SoftRow(
              icon: LucideIcons.star,
              title: context.l10n.github_star_row,
              onTap: () => SettingsActions.openUrl(context, kGitHubUrl),
            ),
            SoftRow(
              icon: LucideIcons.coffee,
              title: context.l10n.buy_coffee,
              onTap: () => SettingsActions.openUrl(context, kCoffeeUrl),
            ),
            SoftRow(
              icon: LucideIcons.messageSquare,
              title: context.l10n.report_issue,
              onTap: () => SettingsActions.openUrl(context, '$kIssuesUrl/new'),
            ),
          ],
        ),
      ],
    );
  }
}
