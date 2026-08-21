import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/todos/data/todo.dart';

const _kBackupVersion = 1;
const _kAutoBackupKeep = 5;

class BackupService {
  const BackupService._();

  static String _payloadFor(List<Habit> habits) {
    final payload = {
      'app': 'streak',
      'version': _kBackupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'notes': LocalStore.readNotes().map((n) => n.toMap()).toList(),
      'focus':
          LocalStore.readFocusSessions().map((f) => f.toMap()).toList(),
      'todos': LocalStore.readTodos().map((t) => t.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
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

  static Future<String?> runAuto({String folder = ''}) async {
    final dir = folder.isEmpty
        ? await defaultBackupDir()
        : Directory(folder);
    if (dir == null) return null;
    try {
      if (!dir.existsSync()) await dir.create(recursive: true);
    } catch (_) {
      return null;
    }

    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${dir.path}/streak_backup_$stamp.json');
    await file.writeAsString(_payloadFor(LocalStore.readHabits().values.toList()));

    final old = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    for (final stale in old.skip(_kAutoBackupKeep)) {
      try {
        stale.deleteSync();
      } catch (_) {}
    }
    return file.path;
  }

  static Future<bool> export(List<Habit> habits) async {
    final content = _payloadFor(habits);
    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    final dir = await Directory.systemTemp.createTemp('streak_backup');
    final file = File('${dir.path}/streak_backup_$stamp.json');
    await file.writeAsString(content);

    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Streak backup',
    );
    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  static Future<List<Habit>> import() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a Streak backup file',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final picked = result.files.single;
    String raw;
    if (picked.bytes != null) {
      raw = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      raw = await File(picked.path!).readAsString();
    } else {
      throw Exception('Could not read the selected file');
    }

    dynamic decoded;
    try {
      decoded = json.decode(raw);
    } catch (_) {
      throw Exception('That file is not a valid backup');
    }

    final List<dynamic> entries;
    if (decoded is List) {
      entries = decoded;
    } else if (decoded is Map && decoded['habits'] is List) {
      entries = decoded['habits'] as List;
    } else {
      throw Exception('Unrecognised backup format');
    }

    final habits = <Habit>[];
    for (final entry in entries) {
      if (entry is! Map) continue;
      try {
        habits.add(Habit.fromMap(Map<String, dynamic>.from(entry)));
      } catch (_) {
      }
    }
    if (habits.isEmpty) throw Exception('No habits found in that file');

    if (decoded is Map) {
      final notes = decoded['notes'];
      if (notes is List) {
        for (final raw in notes) {
          if (raw is Map) {
            await LocalStore.writeNote(
              HabitNote.fromMap(Map<String, dynamic>.from(raw)),
            );
          }
        }
      }
      final focus = decoded['focus'];
      if (focus is List) {
        for (final raw in focus) {
          if (raw is Map) {
            await LocalStore.writeFocusSession(
              FocusSession.fromMap(Map<String, dynamic>.from(raw)),
            );
          }
        }
      }
      final todos = decoded['todos'];
      if (todos is List) {
        for (final raw in todos) {
          if (raw is Map) {
            await LocalStore.writeTodo(
              Todo.fromMap(Map<String, dynamic>.from(raw)),
            );
          }
        }
      }
    }

    return habits;
  }
}
