import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streak/core/database/data_location.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';

class DataFolderActions {
  const DataFolderActions._();

  static bool get available =>
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS) &&
      !isFlatpak;

  static Future<void> pick(BuildContext context) {
    final l10n = context.l10n;
    return showOptionSheet(
      context,
      title: l10n.data_folder,
      options: [
        l10n.data_folder_documents,
        l10n.data_folder_app,
        l10n.data_folder_pick,
      ],
      index: -1,
      onSelected: (index) async {
        final target = await _target(index);
        if (target == null || !context.mounted) return;
        await _move(context, target);
      },
    );
  }

  static Future<Directory?> _target(int index) async {
    switch (index) {
      case 0:
        final documents = await getApplicationDocumentsDirectory();
        return Directory(
          '${documents.path}${Platform.pathSeparator}$appDataFolder',
        );
      case 1:
        return DataLocation.portableDir;
      default:
        final picked = await FilePicker.platform.getDirectoryPath();
        if (picked == null) return null;
        return Directory('$picked${Platform.pathSeparator}$appDataFolder');
    }
  }

  static String _plain(String path) =>
      path.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '').toLowerCase();

  static bool _writable(Directory dir) {
    try {
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final probe = File('${dir.path}/.streak-write-test');
      probe.writeAsStringSync('ok', flush: true);
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _move(BuildContext context, Directory target) async {
    final l10n = context.l10n;
    final current = await appDataDir();
    final from = _plain(current.path);
    final to = _plain(target.path);
    if (!context.mounted || from == to) return;

    if (to.startsWith('$from/') || from.startsWith('$to/')) {
      AppSnackbar.warning(context, l10n.data_folder_inside);
      return;
    }
    if (DataLocation.holdsData(target)) {
      AppSnackbar.warning(context, l10n.data_folder_taken);
      return;
    }
    final fresh = !target.existsSync();
    if (!_writable(target)) {
      AppSnackbar.error(context, l10n.data_folder_denied);
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.data_folder_move_title,
      message: l10n.data_folder_move_body(target.path),
      confirmLabel: l10n.data_folder_move_confirm,
      icon: LucideIcons.folderInput,
      danger: false,
    );
    if (confirmed != true) {
      if (fresh && target.listSync().isEmpty) target.deleteSync();
      return;
    }

    DataLocation.schedule(from: current, to: target);
    await Hive.close();
    exit(0);
  }
}
