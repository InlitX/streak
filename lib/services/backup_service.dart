import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/services/backup_archive.dart';
import 'package:streak/services/import_service.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:streak/services/vault_writer.dart';

const _kBackupVersion = 2;
const _kAutoBackupKeep = 5;
const _kAutoArchiveKeep = 3;
const _kSafetyKeep = 3;

class BackupData {
  const BackupData({
    required this.habits,
    required this.notes,
    required this.focus,
    required this.todos,
    required this.todoTags,
    required this.categories,
    required this.skipped,
    this.exportedAt,
    this.settings = const {},
    this.device = '',
    this.changes = const {},
    this.deleted = const {},
  });

  final List<Habit> habits;
  final List<HabitNote> notes;
  final List<FocusSession> focus;
  final List<Todo> todos;
  final List<TodoTag> todoTags;
  final List<Category> categories;
  final int skipped;
  final DateTime? exportedAt;
  final Map<String, Object?> settings;
  final String device;
  final Map<String, int> changes;
  final Map<String, int> deleted;

  bool get isEmpty =>
      habits.isEmpty && notes.isEmpty && focus.isEmpty && todos.isEmpty;
}

class BackupService {
  const BackupService._();

  static Map<String, Object?> _payload(List<Habit> habits) => {
        'app': 'streak',
        'version': _kBackupVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'device': LocalStore.deviceId,
        'changes': LocalStore.changes,
        'deleted': LocalStore.deleted,
        'habits': habits.map((h) => h.toMap()).toList(),
        'categories':
            LocalStore.readCategories().map((c) => c.toMap()).toList(),
        'notes': LocalStore.readNotes().map((n) => n.toMap()).toList(),
        'focus':
            LocalStore.readFocusSessions().map((f) => f.toMap()).toList(),
        'todos': LocalStore.readTodos().map((t) => t.toMap()).toList(),
        'todoTags': LocalStore.readTodoTags().map((t) => t.toMap()).toList(),
        'settings': {
          for (final key in backupSettingKeys)
            if (LocalStore.setting<Object?>(key, null) case final value?)
              key: value,
        },
      };

  static bool _hasContent(List<Habit> habits) =>
      habits.isNotEmpty ||
      LocalStore.readNotes().isNotEmpty ||
      LocalStore.readTodos().isNotEmpty ||
      LocalStore.readFocusSessions().isNotEmpty;

  static Future<void> safetyCopy() async {
    try {
      final habits = LocalStore.readHabits().values.toList();
      if (!_hasContent(habits)) return;
      final dir = await defaultBackupDir();
      if (dir == null) return;
      if (!dir.existsSync()) await dir.create(recursive: true);
      final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final target = '${dir.path}/streak_safety_$stamp.zip';
      await _settle(File('$target.part'), target, (part) async {
        await BackupArchive.pack(_payload(habits), part.path);
      });
      _prune(dir, 'streak_safety_', '.zip', _kSafetyKeep);
    } catch (e) {
      debugPrint('Safety copy failed: $e');
    }
  }

  static Future<Directory?> defaultBackupDir() async {
    final root = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await appDataDir();
    if (root == null) return null;
    return Directory('${root.path}/backups');
  }

  static Future<bool> ensureStorageAccess() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return true;
    final legacy = await Permission.storage.request();
    return legacy.isGranted;
  }

  static Future<String?> pickBackupFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return null;
    try {
      final probe = File('$path/.streak_write_test');
      await probe.writeAsString('ok');
      await probe.delete();
    } catch (_) {
      return '';
    }
    return path;
  }

  static Future<String?> runAuto({
    String folder = '',
    bool readable = true,
    bool archive = true,
  }) async {
    try {
      final habits = LocalStore.readHabits().values.toList();
      if (!_hasContent(habits)) return null;
      final dir = folder.isEmpty ? await defaultBackupDir() : Directory(folder);
      if (dir == null) return null;
      if (!dir.existsSync()) await dir.create(recursive: true);

      final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final base = '${dir.path}/streak_backup_${stamp}_${LocalStore.deviceId}';
      final payload = _payload(habits);
      final json = await Isolate.run(
        () => const JsonEncoder.withIndent('  ').convert(payload),
      );
      await _settle(File('$base.json.part'), '$base.json', (part) async {
        await part.writeAsString(json, flush: true);
      });
      if (archive) {
        await _settle(File('$base.zip.part'), '$base.zip', (part) async {
          await BackupArchive.pack(payload, part.path);
        });
      }

      if (readable) {
        try {
          await VaultWriter.write(
            Directory('${dir.path}/$vaultFolder'),
            habits: habits,
            categories: LocalStore.readCategories(),
            notes: LocalStore.readNotes(),
            todos: LocalStore.readTodos(),
            focus: LocalStore.readFocusSessions(),
          );
        } catch (e) {
          debugPrint('Could not write the readable copy: $e');
        }
      }

      _prune(dir, 'streak_backup_', '.json', _kAutoBackupKeep);
      _prune(dir, 'streak_backup_', '.zip', _kAutoArchiveKeep);
      return '$base.json';
    } catch (e) {
      debugPrint('Automatic backup failed: $e');
      return null;
    }
  }

  static Future<void> _settle(
    File part,
    String target,
    Future<void> Function(File part) write,
  ) async {
    try {
      await write(part);
      await part.rename(target);
    } finally {
      if (part.existsSync()) part.deleteSync();
    }
  }

  static void _prune(Directory dir, String prefix, String extension, int keep) {
    final old = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = f.uri.pathSegments.last;
          return name.startsWith(prefix) && name.endsWith(extension);
        })
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    for (final stale in old.skip(keep)) {
      try {
        stale.deleteSync();
      } catch (_) {}
    }
  }

  static Future<bool> export(List<Habit> habits, {Rect? origin}) async {
    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final name = 'streak_backup_$stamp.zip';
    final dir = await Directory.systemTemp.createTemp('streak_backup');
    final zip = '${dir.path}/$name';
    await BackupArchive.pack(_payload(habits), zip);

    if (!isMobile) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your Streak backup',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (path == null) return false;
      await File(zip).copy(path);
      return true;
    }

    final result = await Share.shareXFiles(
      [XFile(zip, mimeType: 'application/zip')],
      subject: 'Streak backup',
      sharePositionOrigin: origin,
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  static Future<BackupData> read() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a Streak backup file',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final picked = result.files.single;
    List<int>? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      try {
        bytes = await File(picked.path!).readAsBytes();
      } catch (e) {
        debugPrint('Could not read ${picked.path}: $e');
        throw Exception('That file could not be read');
      }
    }
    if (bytes == null) {
      throw Exception('Could not read the selected file');
    }
    if (ImportService.looksLikeZip(bytes)) {
      final json = await BackupArchive.unpack(bytes, (await appDataDir()).path);
      if (json != null) return parse(json);
    }
    if (ImportService.looksLikeZip(bytes) ||
        ImportService.looksLikeSqlite(bytes)) {
      throw Exception(
        'That is an export from another app, not a Streak backup. '
        'Use "Import from another app" for it.',
      );
    }

    return parse(const Utf8Decoder(allowMalformed: true).convert(bytes));
  }

  static BackupData parse(String raw) {
    dynamic decoded;
    try {
      decoded = json.decode(raw);
    } catch (_) {
      throw Exception('That file is not a valid backup');
    }

    final List<dynamic> entries;
    final Map<String, dynamic> root;
    if (decoded is List) {
      entries = decoded;
      root = const {};
    } else if (decoded is Map && decoded['habits'] is List) {
      entries = decoded['habits'] as List;
      root = Map<String, dynamic>.from(decoded);
    } else {
      throw Exception('Unrecognised backup format');
    }

    var skipped = 0;
    List<T> collect<T>(Object? source, T Function(Map<String, dynamic>) build) {
      if (source is! List) return <T>[];
      final out = <T>[];
      for (final raw in source) {
        if (raw is! Map) {
          skipped++;
          continue;
        }
        try {
          out.add(build(Map<String, dynamic>.from(raw)));
        } catch (_) {
          skipped++;
        }
      }
      return out;
    }

    final habits = collect(entries, Habit.fromMap);
    final data = BackupData(
      habits: habits,
      notes: collect(root['notes'], HabitNote.fromMap),
      focus: collect(root['focus'], FocusSession.fromMap),
      todos: collect(root['todos'], Todo.fromMap),
      todoTags: collect(root['todoTags'], TodoTag.fromMap),
      categories: collect(root['categories'], Category.fromMap),
      skipped: skipped,
      exportedAt: DateTime.tryParse((root['exportedAt'] ?? '') as String),
      settings: root['settings'] is Map
          ? Map<String, Object?>.from(root['settings'] as Map)
          : const {},
      device: root['device'] is String ? root['device'] as String : '',
      changes: _stamps(root['changes']),
      deleted: _stamps(root['deleted']),
    );

    if (data.isEmpty && data.deleted.isEmpty) {
      throw Exception('No habits found in that file');
    }
    return data;
  }

  static Map<String, int> _stamps(Object? source) => source is Map
      ? {
          for (final entry in source.entries)
            if (entry.value is int) '${entry.key}': entry.value as int,
        }
      : const {};
}
