import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/todos/data/todo.dart';

const _kBackupVersion = 1;
const _kAutoBackupKeep = 5;

class BackupData {
  const BackupData({
    required this.habits,
    required this.notes,
    required this.focus,
    required this.todos,
    required this.categories,
    required this.skipped,
  });

  final List<Habit> habits;
  final List<HabitNote> notes;
  final List<FocusSession> focus;
  final List<Todo> todos;
  final List<Category> categories;
  final int skipped;

  bool get isEmpty =>
      habits.isEmpty && notes.isEmpty && focus.isEmpty && todos.isEmpty;
}

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
      'categories':
          LocalStore.readCategories().map((c) => c.toMap()).toList(),
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

  static Future<bool> export(List<Habit> habits, {Rect? origin}) async {
    final content = _payloadFor(habits);
    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    final dir = await Directory.systemTemp.createTemp('streak_backup');
    final file = File('${dir.path}/streak_backup_$stamp.json');
    await file.writeAsString(content);

    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
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
    String raw;
    if (picked.bytes != null) {
      raw = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      raw = await File(picked.path!).readAsString();
    } else {
      throw Exception('Could not read the selected file');
    }

    return parse(raw);
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
      categories: collect(root['categories'], Category.fromMap),
      skipped: skipped,
    );

    if (data.isEmpty) throw Exception('No habits found in that file');
    return data;
  }
}
