import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/notification_service.dart';

class FolderSync {
  const FolderSync._();

  static const _prefix = 'streak_backup_';
  static const _seenKey = 'folderSeenAt';

  static bool get isSet =>
      LocalStore.setting('autoBackupFolder', '').isNotEmpty;

  static final _settled = <String>{};
  static DateTime? _settledSince;

  static Future<int> pull() async {
    final folder = LocalStore.setting('autoBackupFolder', '');
    if (folder.isEmpty) return 0;
    try {
      final since = DateTime.tryParse(LocalStore.setting(_seenKey, ''));
      final batch = incoming(Directory(folder), since);
      if (batch.isEmpty) return 0;
      var brought = 0;
      for (final data in batch) {
        brought += await _absorb(data);
      }
      await LocalStore.writeSetting(
        _seenKey,
        batch.last.exportedAt!.toIso8601String(),
      );
      return brought;
    } catch (e) {
      debugPrint('Could not read the shared folder: $e');
      return 0;
    }
  }

  static List<BackupData> incoming(Directory dir, DateTime? since) {
    final self = LocalStore.deviceId;
    if (since != _settledSince) {
      _settled.clear();
      _settledSince = since;
    }
    final found = <BackupData>[];
    for (final file in backupsIn(dir)) {
      final name = _name(file);
      if (name.endsWith('_$self.json') || _settled.contains(file.path)) continue;
      final BackupData data;
      try {
        data = BackupService.parse(file.readAsStringSync());
      } catch (e) {
        debugPrint('Skipping $name: $e');
        _settled.add(file.path);
        continue;
      }
      final written = data.exportedAt;
      if (written == null || (since != null && !written.isAfter(since))) {
        _settled.add(file.path);
        break;
      }
      if (data.device == self || (data.isEmpty && data.deleted.isEmpty)) {
        _settled.add(file.path);
        continue;
      }
      found.add(data);
    }
    return found.reversed.toList();
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

  static Future<int> _absorb(BackupData data) =>
      LocalStore.quietly(() => _take(data));

  static Future<int> _take(BackupData data) async {
    final stamps = data.changes;
    final deletes = LocalStore.setting('autoSync', false);
    var brought = deletes ? await _forget(data.deleted) : 0;

    for (final theirs in data.habits) {
      if (deletes && _buried(theirs.id, stamps[theirs.id])) continue;
      final ours = LocalStore.habit(theirs.id);
      final newer = _theirsNewer(stamps[theirs.id], theirs.id);
      final merged = ours == null
          ? theirs
          : (newer ? theirs : ours).copyWith(
              completions: mergeCompletions(ours.completions, theirs.completions),
              missReasons: {...theirs.missReasons, ...ours.missReasons},
            );
      if (ours != null && _same(ours.toMap(), merged.toMap())) continue;
      brought++;
      await LocalStore.writeHabit(merged);
      if (newer) await _adopt(theirs.id, stamps[theirs.id]);
    }

    for (final category in data.categories) {
      await LocalStore.mergeCategory(category);
    }
    bool orphan(String habitId) =>
        deletes && LocalStore.habit(habitId) == null && LocalStore.deletedAt(habitId) != null;
    brought += await _records(data.notes.where((n) => !orphan(n.habitId)), stamps, deletes,
        (n) => n.id, LocalStore.note, (n) => n.toMap(), LocalStore.writeNote);
    brought += await _records(data.focus.where((f) => !orphan(f.habitId)), stamps, deletes,
        (f) => f.id, LocalStore.focusSession, (f) => f.toMap(), LocalStore.writeFocusSession);
    brought += await _records(data.todos, stamps, deletes, (t) => t.id,
        LocalStore.todo, (t) => t.toMap(), LocalStore.writeTodo);
    brought += await _records(data.todoTags, stamps, deletes, (t) => t.id,
        LocalStore.todoTag, (t) => t.toMap(), LocalStore.writeTodoTag);
    return brought;
  }

  static Future<int> _forget(Map<String, int> deleted) async {
    var brought = 0;
    for (final MapEntry(key: id, value: at) in deleted.entries) {
      final known = LocalStore.deletedAt(id);
      if (known != null && known >= at) continue;
      final edited = LocalStore.changedAt(id);
      if (edited != null && edited > at) continue;
      if (await _remove(id)) brought++;
      await LocalStore.stampDeleted(id, at);
    }
    return brought;
  }

  static Future<bool> _remove(String id) async {
    final notifications = NotificationService();
    if (LocalStore.habit(id) != null) {
      try {
        await notifications.cancelFor(id);
      } catch (e) {
        debugPrint('Could not cancel the reminders of $id: $e');
      }
      await LocalStore.removeHabit(id);
      await LocalStore.removeNotesFor(id);
      await LocalStore.removeFocusFor(id);
      return true;
    }
    if (LocalStore.todo(id) != null) {
      try {
        await notifications.cancelTodo(id);
      } catch (e) {
        debugPrint('Could not cancel the reminder of $id: $e');
      }
      await LocalStore.removeTodo(id);
      return true;
    }
    if (LocalStore.note(id) != null) {
      await LocalStore.removeNote(id);
      return true;
    }
    if (LocalStore.focusSession(id) != null) {
      await LocalStore.removeFocusSessions([id]);
      return true;
    }
    if (LocalStore.todoTag(id) != null) {
      await LocalStore.removeTodoTag(id);
      return true;
    }
    return false;
  }

  static bool _buried(String id, int? theirs) {
    final gone = LocalStore.deletedAt(id);
    return gone != null && (theirs == null || theirs <= gone);
  }

  static Future<int> _records<T>(
    Iterable<T> items,
    Map<String, int> stamps,
    bool deletes,
    String Function(T) idOf,
    T? Function(String) ours,
    Map<String, dynamic> Function(T) mapOf,
    Future<void> Function(T) write,
  ) async {
    var brought = 0;
    for (final theirs in items) {
      final id = idOf(theirs);
      if (deletes && _buried(id, stamps[id])) continue;
      final mine = ours(id);
      if (mine != null &&
          (!_theirsNewer(stamps[id], id) || _same(mapOf(mine), mapOf(theirs)))) {
        continue;
      }
      brought++;
      await write(theirs);
      await _adopt(id, stamps[id]);
    }
    return brought;
  }

  static bool _theirsNewer(int? theirs, String id) {
    final ours = LocalStore.changedAt(id);
    if (theirs == null) return ours == null;
    return ours == null || theirs > ours;
  }

  static Future<void> _adopt(String id, int? at) async {
    if (at != null) await LocalStore.stampChange(id, at);
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

  static bool _same(Map<String, dynamic> a, Map<String, dynamic> b) =>
      json.encode(a) == json.encode(b);

  static String _name(File file) => file.uri.pathSegments.last;
}
