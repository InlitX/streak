import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/section_label.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/services/import_service.dart';
import 'package:streak/features/habits/widgets/color_picker.dart';
import 'package:streak/features/settings/pages/about_page.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

const _kGitHubUrl = 'https://github.com/InlitX/streak';
const _kIssuesUrl = 'https://github.com/InlitX/streak/issues';
const _kCoffeeUrl = 'https://ko-fi.com/inlitx';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _export() async {
    final controller = context.read<HabitsController>();
    final ok = await controller.exportBackup();
    if (!mounted) return;
    ok
        ? AppSnackbar.success(context, context.l10n.backup_saved)
        : AppSnackbar.warning(context, context.l10n.export_cancelled);
  }

  Future<void> _import() async {
    final controller = context.read<HabitsController>();
    final replace = await _askImportMode();
    if (replace == null || !mounted) return;
    final error = await controller.importBackup(replace: replace);
    if (!mounted) return;
    error == null
        ? AppSnackbar.success(context, context.l10n.habits_imported)
        : AppSnackbar.error(context, error);
  }

  Future<void> _importFromApp() async {
    final controller = context.read<HabitsController>();
    try {
      final outcome = await controller.importFromApp();
      if (!mounted || outcome == null) return;
      AppSnackbar.success(
        context,
        context.l10n.import_from_app_done(
          outcome.habits.length,
          outcome.entries,
          outcome.source,
        ),
      );
    } on ImportException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, context.l10n.import_failed);
    }
  }

  Future<bool?> _askImportMode() {
    return showDialog<bool?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.import_backup),
        content: Text(context.l10n.import_question_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.import_merge),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.import_replace,
              style: TextStyle(color: context.tokens.danger),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final settings = context.read<SettingsController>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    final old = settings.profilePhoto;
    await settings.setProfilePhoto(dest);
    if (old.isNotEmpty && old != dest) {
      try {
        await File(old.split('?').first).delete();
      } catch (_) {}
    }
  }

  Future<void> _editName() async {
    final settings = context.read<SettingsController>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: settings.profileName),
    );
    if (name != null) await settings.setProfileName(name);
  }

  void _openAccentSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.accent_color,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Consumer<SettingsController>(
                builder: (_, s, __) => ColorPicker(
                  selected: s.accentColor,
                  onSelected: s.setAccentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _bgLabel(BuildContext context, int index) => switch (index) {
        1 => context.l10n.bg_gradient,
        2 => context.l10n.bg_dots,
        3 => context.l10n.bg_oled,
        4 => context.l10n.custom,
        _ => context.l10n.bg_solid,
      };

  void _openBackgroundSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.app_background,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Consumer<SettingsController>(
                builder: (_, s, __) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _BackgroundOption(
                          index: i,
                          selected: s.appBackground == i,
                          label: _bgLabel(context, i),
                          onTap: () => s.setAppBackground(i),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CustomBackgroundOption(
                        selected: s.appBackground == 4,
                        imagePath: s.bgImage,
                        label: context.l10n.custom,
                        onTap: _pickBackgroundImage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    final settings = context.read<SettingsController>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest =
        '${dir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    final old = settings.bgImage;
    await settings.setBackgroundImage(dest);
    await settings.setAppBackground(4);
    if (old.isNotEmpty && old != dest) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  void _openLanguageSheet() {
    final locales = AppLocalizations.supportedLocales;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Consumer<SettingsController>(
            builder: (_, s, __) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.language,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _LanguageTile(
                        label: context.l10n.system,
                        selected: s.localeCode.isEmpty,
                        onTap: () => _chooseLanguage(''),
                      ),
                      for (final l in locales)
                        _LanguageTile(
                          label: _languageName(l),
                          selected: s.localeCode == l.toString(),
                          onTap: () => _chooseLanguage(l.toString()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _chooseLanguage(String code) {
    context.read<SettingsController>().setLanguage(code);
    Navigator.of(context).pop();
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(
              name: settings.profileName.isEmpty
                  ? context.l10n.default_user
                  : settings.profileName,
              photoPath: settings.profilePhoto,
              onTapPhoto: _pickProfilePhoto,
              onTapName: _editName,
            ),
            const SizedBox(height: 24),
            SectionLabel(context.l10n.about),
            Card(
              child: _NavRow(
                icon: LucideIcons.info,
                title: context.l10n.about_app,
                subtitle: context.l10n.about_app_sub,
                onTap: () => AppNavigator.push(const AboutPage()),
              ),
            ),
            const SizedBox(height: 24),
            SectionLabel(context.l10n.preferences),
            Card(
              child: Column(
                children: [
                  _SettingRow(
                    icon: LucideIcons.sunMoon,
                    title: context.l10n.theme,
                    trailing: _Segmented(
                      options: [
                        context.l10n.system,
                        context.l10n.light,
                        context.l10n.dark,
                      ],
                      index: settings.themeMode.index,
                      onChanged: (i) =>
                          settings.setThemeMode(ThemeMode.values[i]),
                    ),
                  ),
                  _divider(context),
                  _PickerRow(
                    icon: LucideIcons.languages,
                    title: context.l10n.language,
                    value: _languageLabel(context, settings.localeCode),
                    onTap: _openLanguageSheet,
                  ),
                  _divider(context),
                  _SettingRow(
                    icon: LucideIcons.calendarDays,
                    title: context.l10n.week_starts_on,
                    trailing: _Segmented(
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
                        switch (i) { 1 => 6, 2 => 7, _ => 1 },
                      ),
                    ),
                  ),
                  _divider(context),
                  _SettingRow(
                    icon: LucideIcons.arrowDownWideNarrow,
                    title: context.l10n.sort_completed_last,
                    trailing: _Segmented(
                      options: [context.l10n.off, context.l10n.on],
                      index: settings.sortCompletedLast ? 1 : 0,
                      onChanged: (i) => settings.setSortCompletedLast(i == 1),
                    ),
                  ),
                  _divider(context),
                  _SettingRow(
                    icon: LucideIcons.squareCheck,
                    title: context.l10n.check_style,
                    trailing: _Segmented(
                      options: [context.l10n.square, context.l10n.circle],
                      index: settings.checkStyle,
                      onChanged: settings.setCheckStyle,
                    ),
                  ),
                  _divider(context),
                  _SettingRow(
                    icon: LucideIcons.smartphone,
                    title: context.l10n.app_icon,
                    trailing: _Segmented(
                      options: [
                        context.l10n.icon_default,
                        context.l10n.icon_neutral,
                        context.l10n.icon_accent,
                      ],
                      index: settings.appIcon,
                      onChanged: settings.setAppIcon,
                    ),
                  ),
                  _divider(context),
                  InkWell(
                    onTap: _openBackgroundSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const _IconBadge(icon: LucideIcons.image),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              context.l10n.app_background,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _bgLabel(context, settings.appBackground),
                            style: TextStyle(
                              color: context.tokens.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.chevronRight,
                              size: 18, color: context.tokens.muted),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionLabel(context.l10n.accent_color),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openAccentSheet,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const _IconBadge(icon: LucideIcons.palette),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.l10n.accent_color,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: settings.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  settings.accentColor.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(LucideIcons.chevronRight,
                          size: 18, color: context.tokens.muted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionLabel(context.l10n.data),
            Card(
              child: Column(
                children: [
                  _NavRow(
                    icon: LucideIcons.import,
                    title: context.l10n.import_from_app,
                    subtitle: context.l10n.import_from_app_sub,
                    badge: 'Beta',
                    onTap: _importFromApp,
                  ),
                  _divider(context),
                  _NavRow(
                    icon: LucideIcons.upload,
                    title: context.l10n.import_backup,
                    subtitle: context.l10n.import_backup_sub,
                    onTap: _import,
                  ),
                  _divider(context),
                  _NavRow(
                    icon: LucideIcons.download,
                    title: context.l10n.export_backup,
                    subtitle: context.l10n.export_backup_sub,
                    onTap: _export,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionLabel(context.l10n.support),
            Card(
              child: Column(
                children: [
                  _MinimalRow(
                    icon: LucideIcons.star,
                    title: context.l10n.github_star_row,
                    onTap: () => _open(_kGitHubUrl),
                  ),
                  _divider(context),
                  _MinimalRow(
                    icon: LucideIcons.coffee,
                    title: context.l10n.buy_coffee,
                    onTap: () => _open(_kCoffeeUrl),
                  ),
                  _divider(context),
                  _MinimalRow(
                    icon: LucideIcons.bug,
                    title: context.l10n.report_bug,
                    onTap: () => _open(_kIssuesUrl),
                  ),
                  _divider(context),
                  _MinimalRow(
                    icon: LucideIcons.lightbulb,
                    title: context.l10n.request_feature,
                    onTap: () => _open('$_kIssuesUrl/new'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        indent: 60,
        endIndent: 16,
        color: context.colors.surfaceContainerHighest,
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.photoPath,
    required this.onTapPhoto,
    required this.onTapName,
  });

  final String name;
  final String photoPath;
  final VoidCallback onTapPhoto;
  final VoidCallback onTapName;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final filePath = photoPath.split('?').first;
    final hasPhoto = filePath.isNotEmpty && File(filePath).existsSync();

    return Column(
      children: [
        GestureDetector(
          onTap: onTapPhoto,
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
                  child: Icon(LucideIcons.pencil,
                      size: 12, color: scheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTapName,
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
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconBadge(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _IconBadge(icon: icon),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            _TagPill(label: badge!),
          ],
        ],
      ),
      subtitle: Text(subtitle, style: TextStyle(color: context.tokens.muted)),
      trailing:
          Icon(LucideIcons.chevronRight, size: 18, color: context.tokens.muted),
      onTap: onTap,
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _MinimalRow extends StatelessWidget {
  const _MinimalRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: context.tokens.muted),
      horizontalTitleGap: 12,
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing:
          Icon(LucideIcons.chevronRight, size: 18, color: context.tokens.muted),
      onTap: onTap,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: context.colors.onSurface, size: 16),
    );
  }
}

String _languageLabel(BuildContext context, String code) =>
    code.isEmpty ? context.l10n.system : _languageName(localeFromCode(code));

String _languageName(Locale locale) {
  const names = <String, String>{
    'en': 'English',
    'es': 'Español',
    'zh': '简体中文',
    'de': 'Deutsch',
    'fr': 'Français',
    'pt': 'Português',
    'it': 'Italiano',
    'ru': 'Русский',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
    'tr': 'Türkçe',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'uk': 'Українська',
    'hi': 'हिन्दी',
    'id': 'Bahasa Indonesia',
    'cs': 'Čeština',
    'sv': 'Svenska',
    'vi': 'Tiếng Việt',
  };
  final base =
      names[locale.languageCode] ?? locale.languageCode.toUpperCase();
  return locale.countryCode == null ? base : '$base (${locale.countryCode})';
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.tokens.muted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 18, color: context.tokens.muted),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : null,
                ),
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.index,
    required this.onChanged,
  });

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: i == index ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  options[i],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: i == index ? scheme.onPrimary : context.tokens.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BackgroundOption extends StatelessWidget {
  const _BackgroundOption({
    required this.index,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  BoxDecoration _preview(bool isDark) {
    if (isDark) {
      switch (index) {
        case 1:
          return const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF262626), Color(0xFF0A0A0A)],
            ),
          );
        case 3:
          return const BoxDecoration(color: Color(0xFF000000));
        default:
          return const BoxDecoration(color: Color(0xFF161616));
      }
    }
    switch (index) {
      case 1:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFDAD8EC)],
          ),
        );
      case 3:
        return const BoxDecoration(color: Color(0xFFFFFFFF));
      default:
        return const BoxDecoration(color: Color(0xFFEDEDF3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD8D8E0);
    final dotColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: _preview(isDark).copyWith(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accent : outline,
                  width: selected ? 2 : 1,
                ),
              ),
              child: index == 2
                  ? CustomPaint(painter: _MiniDotsPainter(dotColor))
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? accent : context.tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBackgroundOption extends StatelessWidget {
  const _CustomBackgroundOption({
    required this.selected,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD8D8E0);
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161616)
                    : const Color(0xFFEDEDF3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accent : outline,
                  width: selected ? 2 : 1,
                ),
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasImage
                  ? null
                  : Icon(LucideIcons.imagePlus,
                      size: 20, color: context.tokens.muted),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? accent : context.tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDotsPainter extends CustomPainter {
  _MiniDotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = 6.0; y < size.height; y += 8) {
      for (var x = 6.0; x < size.width; x += 8) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniDotsPainter oldDelegate) => oldDelegate.color != color;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.edit_name),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: context.l10n.your_name),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}
