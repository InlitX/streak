import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_lock.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/utils/share_origin.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/services/notification_service.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/import_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const kGitHubUrl = 'https://github.com/InlitX/streak';
const kIssuesUrl = 'https://github.com/InlitX/streak/issues';
const kCoffeeUrl = 'https://ko-fi.com/inlitx';

class SettingsActions {
  const SettingsActions._();

  static Future<void> openUrl(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) AppSnackbar.error(context, url);
    }
  }

  static Future<void> exportBackup(BuildContext context) async {
    final controller = context.read<HabitsController>();
    final ok = await controller.exportBackup(origin: shareOrigin(context));
    if (!context.mounted) return;
    ok
        ? AppSnackbar.success(context, context.l10n.backup_saved)
        : AppSnackbar.warning(context, context.l10n.export_cancelled);
  }

  static Future<void> importBackup(BuildContext context) async {
    final controller = context.read<HabitsController>();
    final replace = await _askImportMode(context);
    if (replace == null || !context.mounted) return;
    final error = await controller.importBackup(replace: replace);
    if (!context.mounted) return;
    if (error == null) {
      context.read<NotesController>().reload();
      context.read<FocusController>().reload();
      context.read<TodosController>().reload();
      context.read<CategoriesController>().reload();
      AppSnackbar.success(context, context.l10n.habits_imported);
    } else {
      AppSnackbar.error(context, error);
    }
  }

  static Future<void> importFromApp(BuildContext context) async {
    final controller = context.read<HabitsController>();
    try {
      final outcome = await controller.importFromApp();
      if (!context.mounted || outcome == null) return;
      AppSnackbar.success(
        context,
        context.l10n.import_from_app_done(
          outcome.habits.length,
          outcome.entries,
          outcome.source,
        ),
      );
    } on ImportException catch (e) {
      if (context.mounted) AppSnackbar.error(context, e.message);
    } catch (_) {
      if (context.mounted) AppSnackbar.error(context, context.l10n.import_failed);
    }
  }

  static String autoBackupLabel(BuildContext context, int value) => switch (value) {
        1 => context.l10n.auto_backup_daily,
        2 => context.l10n.auto_backup_weekly,
        _ => context.l10n.auto_backup_off,
      };

  static String autoBackupSubtitle(BuildContext context) {
    final settings = context.watch<SettingsController>();
    if (settings.autoBackup == 0) return context.l10n.auto_backup_sub;
    final last = settings.autoBackupAt;
    final label = autoBackupLabel(context, settings.autoBackup);
    if (last == null) return label;
    final locale = Localizations.localeOf(context).toString();
    return '$label  ·  ${DateFormat.yMMMd(locale).add_Hm().format(last)}';
  }

  static String backupFolderLabel(BuildContext context, String path) {
    if (path.isEmpty) return context.l10n.auto_backup_folder_default;
    final parts = path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }

  static Future<void> chooseBackupFolder(BuildContext context) async {
    final settings = context.read<SettingsController>();
    if (!await BackupService.ensureStorageAccess()) {
      if (context.mounted) {
        AppSnackbar.warning(context, context.l10n.auto_backup_no_permission);
      }
      return;
    }
    final picked = await BackupService.pickBackupFolder();
    if (picked == null) return;
    if (picked.isEmpty) {
      if (context.mounted) {
        AppSnackbar.error(context, context.l10n.auto_backup_folder_failed);
      }
      return;
    }
    await settings.setAutoBackupFolder(picked);
    if (context.mounted) {
      AppSnackbar.success(context, context.l10n.auto_backup_folder_set);
    }
  }

  static Future<void> pickAutoBackup(BuildContext context) async {
    final settings = context.read<SettingsController>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        top: false,
        child: Consumer<SettingsController>(
          builder: (sheetContext, s, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetTitle(
                  context.l10n.auto_backup,
                  subtitle: context.l10n.auto_backup_where,
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < 3; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      autoBackupLabel(context, i),
                      style: sheetOptionStyle(
                        sheetContext,
                        selected: s.autoBackup == i,
                      ),
                    ),
                    trailing: s.autoBackup == i
                        ? Icon(LucideIcons.check, color: context.colors.primary)
                        : null,
                    onTap: () => settings.setAutoBackup(i),
                  ),
                const Divider(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(LucideIcons.folder, color: context.tokens.muted),
                  title: Text(
                    context.l10n.auto_backup_folder,
                    style: sheetOptionStyle(sheetContext, size: 15),
                  ),
                  subtitle: Text(
                    backupFolderLabel(context, s.autoBackupFolder),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: s.autoBackupFolder.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => settings.setAutoBackupFolder(''),
                        ),
                  onTap: () => chooseBackupFolder(sheetContext),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await settings.runAutoBackup(force: true);
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheet).pop();
                      ok
                          ? AppSnackbar.success(
                              context, context.l10n.backup_saved)
                          : AppSnackbar.error(
                              context, context.l10n.auto_backup_folder_failed);
                    },
                    icon: const Icon(LucideIcons.play, size: 16),
                    label: Text(context.l10n.auto_backup_run_now),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> clearProgress(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.clear_progress,
      message: context.l10n.clear_progress_warning,
      confirmLabel: context.l10n.clear_progress_confirm,
      icon: LucideIcons.eraser,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<HabitsController>().clearProgress();
    if (!context.mounted) return;
    context.read<NotesController>().reload();
    context.read<FocusController>().reload();
    if (!context.mounted) return;
    AppSnackbar.success(context, context.l10n.clear_progress_done);
  }

  static Future<void> wipeEverything(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.wipe_data,
      message: context.l10n.wipe_data_warning,
      confirmLabel: context.l10n.wipe_data_confirm,
      icon: LucideIcons.triangleAlert,
    );
    if (confirmed != true || !context.mounted) return;

    final again = await showAppConfirmDialog(
      context,
      title: context.l10n.wipe_data_sure,
      message: context.l10n.wipe_data_sure_body,
      confirmLabel: context.l10n.wipe_data_confirm,
      icon: LucideIcons.triangleAlert,
    );
    if (again != true || !context.mounted) return;

    await NotificationService().cancelAll();
    await LocalStore.wipeEverything();
    if (!context.mounted) return;
    await context.read<HabitsController>().reload();
    if (!context.mounted) return;
    context.read<NotesController>().reload();
    context.read<FocusController>().reload();
    context.read<TodosController>().reload();
    context.read<CategoriesController>().reload();
    await context.read<SettingsController>().reloadFromStore();
    if (!context.mounted) return;
    AppSnackbar.success(context, context.l10n.wipe_data_done);
    await openAppSettings();
  }

  static Future<void> toggleAppLock(BuildContext context, bool value) async {
    final settings = context.read<SettingsController>();
    if (!value) {
      await AppLockService.setSecure(false);
      await settings.setAppLock(false);
      return;
    }
    if (!await AppLockService.isAvailable()) {
      if (context.mounted) {
        AppSnackbar.warning(context, context.l10n.app_lock_unavailable);
      }
      return;
    }
    if (!context.mounted) return;
    final ok = await AppLockService.authenticate(context.l10n.app_lock_sub);
    if (!context.mounted) return;
    if (!ok) {
      AppSnackbar.error(context, context.l10n.app_lock_failed);
      return;
    }
    await AppLockService.setSecure(true);
    await settings.setAppLock(true);
  }

  static Future<void> shareWithFriend(BuildContext context) async {
    await Share.share(
      context.l10n.share_friends_message,
      sharePositionOrigin: shareOrigin(context),
    );
  }

  static Future<bool?> _askImportMode(BuildContext context) {
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

  static Future<void> pickProfilePhoto(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final dir = await appDataDir();
    final dest =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    final old = settings.profilePhoto;
    await settings.setProfilePhoto(dest);
    if (old.isNotEmpty && old != dest) {
      try {
        await File(old.split('?').first).delete();
      } catch (_) {}
    }
  }

  static Future<void> pickBackgroundImage(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    final dir = await appDataDir();
    final dest = '${dir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  static Future<void> setVacationAll(BuildContext context, bool on) async {
    final settings = context.read<SettingsController>();
    final habits = context.read<HabitsController>();
    if (!on) {
      await habits.resumeAll(settings.vacationAllIds);
      await settings.setVacationAll(false, const []);
      return;
    }
    await settings.setVacationAll(true, await habits.pauseAll());
  }

  static Future<void> editName(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: settings.profileName),
    );
    if (name != null) await settings.setProfileName(name);
  }

  static const appLockDelays = [0, 30, 60, 300];

  static int appLockDelayIndex(int seconds) {
    final index = appLockDelays.indexOf(seconds);
    return index < 0 ? 0 : index;
  }

  static List<String> appLockDelayLabels(BuildContext context) => [
        context.l10n.app_lock_delay_instant,
        context.l10n.app_lock_delay_seconds('30'),
        context.l10n.minutes_short('1'),
        context.l10n.minutes_short('5'),
      ];

  static List<String> startViewLabels(BuildContext context) => [
        context.l10n.start_view_last,
        context.l10n.week,
        context.l10n.month,
        context.l10n.year,
      ];

  static List<String> celebrationLabels(BuildContext context) => [
        context.l10n.celebration_confetti,
        context.l10n.celebration_fireworks,
        context.l10n.celebration_surprise,
        context.l10n.celebration_none,
      ];

  static List<String> dayStartLabels(BuildContext context) => [
        context.l10n.day_start_midnight,
        for (var h = 1; h <= 6; h++) context.l10n.day_start_hour('$h'),
      ];

  static String backgroundLabel(BuildContext context, int index) =>
      switch (index) {
        1 => context.l10n.bg_gradient,
        2 => context.l10n.bg_dots,
        3 => context.l10n.bg_oled,
        4 => context.l10n.custom,
        _ => context.l10n.bg_solid,
      };

  static const shippedLanguages = {'en', 'es', 'pt', 'ru', 'uk', 'zh'};

  static List<Locale> get shippedLocales => AppLocalizations.supportedLocales
      .where((l) => shippedLanguages.contains(l.languageCode))
      .toList();

  static String languageLabel(BuildContext context, String code) =>
      code.isEmpty ? context.l10n.system : languageName(localeFromCode(code));

  static String languageName(Locale locale) {
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
    final base = names[locale.languageCode] ?? locale.languageCode.toUpperCase();
    return locale.countryCode == null ? base : '$base (${locale.countryCode})';
  }
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
