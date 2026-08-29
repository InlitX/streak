import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/backup_service.dart';

class FolderSync {
  const FolderSync._();

  static const _prefix = 'streak_backup_';
  static const _seenKey = 'folderSeenAt';

  static bool get isSet =>
      LocalStore.setting('autoBackupFolder', '').isNotEmpty;

  static Future<int> pull() async {
    final folder = LocalStore.setting('autoBackupFolder', '');
    if (folder.isEmpty) return 0;
    try {
      final since = DateTime.tryParse(LocalStore.setting(_seenKey, ''));
      final data = incoming(Directory(folder), since);
      if (data == null) return 0;
      final brought = await _absorb(data);
      await LocalStore.writeSetting(
        _seenKey,
        data.exportedAt!.toIso8601String(),
      );
      return brought;
    } catch (e) {
      debugPrint('Could not read the shared folder: $e');
      return 0;
    }
  }

  static BackupData? incoming(Directory dir, DateTime? since) {
    for (final file in backupsIn(dir)) {
      final BackupData data;
      try {
        data = BackupService.parse(file.readAsStringSync());
      } catch (e) {
        debugPrint('Skipping ${_name(file)}: $e');
        continue;
      }
      final written = data.exportedAt;
      if (written == null) return null;
      if (since != null && !written.isAfter(since)) return null;
      return data.isEmpty ? null : data;
    }
    return null;
  }

  static List<File> backupsIn(Directory dir) {
    if (!dir.existsSync()) return const [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => _name(f).startsWith(_prefix) && _name(f).endsWith('.json'))
        .toList()
      ..sort((a, b) => _name(b).compareTo(_name(a)));
  }

  static Future<int> _absorb(BackupData data) async {
    final local = LocalStore.readHabits();
    var brought = 0;

    for (final theirs in data.habits) {
      final ours = local[theirs.id];
      final merged = ours == null
          ? theirs
          : theirs.copyWith(
              completions: mergeCompletions(ours.completions, theirs.completions),
            );
      if (ours != null && _same(ours, merged)) continue;
      brought++;
      await LocalStore.writeHabit(merged);
    }

    for (final category in data.categories) {
      await LocalStore.writeCategory(category);
    }
    for (final note in data.notes) {
      await LocalStore.writeNote(note);
    }
    for (final session in data.focus) {
      await LocalStore.writeFocusSession(session);
    }
    for (final todo in data.todos) {
      await LocalStore.writeTodo(todo);
    }
    return brought;
  }

  static Map<String, Completion> mergeCompletions(
    Map<String, Completion> ours,
    Map<String, Completion> theirs,
  ) {
    final out = {...ours};
    for (final entry in theirs.entries) {
      final mine = out[entry.key];
      final other = entry.value;
      if (mine == null) {
        out[entry.key] = other;
        continue;
      }
      out[entry.key] = Completion(
        date: other.date,
        count: mine.count >= other.count ? mine.count : other.count,
        hour: mine.hour ?? other.hour,
        steps: {...mine.steps, ...other.steps},
      );
    }
    return out;
  }

  static bool _same(Habit a, Habit b) =>
      json.encode(a.toMap()) == json.encode(b.toMap());

  static String _name(File file) => file.uri.pathSegments.last;
}
