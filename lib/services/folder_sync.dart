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
  static const _seenByKey = 'folderSeenBy';

  static bool get isSet =>
      LocalStore.setting('autoBackupFolder', '').isNotEmpty;

  static final _peeked =
      <String, ({DateTime modified, DateTime? at, String device})>{};

  static Future<int> pull() async {
    final folder = LocalStore.setting('autoBackupFolder', '');
    if (folder.isEmpty) return 0;
    try {
      final since = DateTime.tryParse(LocalStore.setting(_seenKey, ''));
      final seen = {
        for (final MapEntry(:key, :value)
            in LocalStore.settingMap(_seenByKey).entries)
          if (DateTime.tryParse('$value') case final at?) key: at,
      };
      final batch = incoming(Directory(folder), since, seen);
      if (batch.isEmpty) return 0;
      var brought = 0;
      var latest = since;
      for (final data in batch) {
        brought += await _absorb(data);
        final at = data.exportedAt!;
        if (data.device.isEmpty) {
          if (latest == null || at.isAfter(latest)) latest = at;
        } else {
          final known = seen[data.device];
          if (known == null || at.isAfter(known)) seen[data.device] = at;
        }
      }
      if (latest != null && latest != since) {
        await LocalStore.writeSetting(_seenKey, latest.toIso8601String());
      }
      await LocalStore.writeSetting(_seenByKey, {
        for (final MapEntry(:key, :value) in seen.entries)
          key: value.toIso8601String(),
      });
      return brought;
    } catch (e) {
      debugPrint('Could not read the shared folder: $e');
      return 0;
    }
  }

  static List<BackupData> incoming(
    Directory dir,
    DateTime? since, [
    Map<String, DateTime> seen = const {},
  ]) {
    final self = LocalStore.deviceId;
    bool taken(DateTime? at, String device) {
      final mark = device.isEmpty ? since : seen[device];
      return at == null ||
          device == self ||
          (mark != null && !at.isAfter(mark));
    }

    final found = <BackupData>[];
    for (final file in backupsIn(dir)) {
      final name = _name(file);
      if (name.endsWith('_$self.json')) continue;
      final DateTime modified;
      try {
        modified = file.lastModifiedSync();
      } catch (_) {
        continue;
      }
      final peek = _peeked[file.path];
      if (peek != null &&
          peek.modified == modified &&
          taken(peek.at, peek.device)) {
        continue;
      }
      final BackupData data;
      try {
        data = BackupService.parse(file.readAsStringSync());
      } catch (e) {
        debugPrint('Skipping $name: $e');
        _peeked[file.path] = (modified: modified, at: null, device: '');
        continue;
      }
      final empty = data.isEmpty && data.deleted.isEmpty;
      _peeked[file.path] = (
        modified: modified,
        at: empty ? null : data.exportedAt,
        device: data.device,
      );
      if (empty || taken(data.exportedAt, data.device)) continue;
      found.add(data);
    }
    return found..sort((a, b) => a.exportedAt!.compareTo(b.exportedAt!));
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
      final id = theirs.id;
      if (deletes && _buried(id, stamps[id])) continue;
      final ours = LocalStore.habit(id);
      final newer = _theirsNewer(stamps[id], id);
      final ourCut = LocalStore.clearedAt(id);
      final theirCut = data.cleared[id];
      final cut = _later(ourCut, theirCut);
      final theirDays = _since(theirs.completions, cut, theirCut);
      final merged = ours == null
          ? theirs.copyWith(completions: theirDays)
          : (newer ? theirs : ours).copyWith(
              completions: mergeCompletions(
                _since(ours.completions, cut, ourCut),
                theirDays,
              ),
              missReasons: newer
                  ? {...ours.missReasons, ...theirs.missReasons}
                  : {...theirs.missReasons, ...ours.missReasons},
            );
      if (cut != null && cut != ourCut) {
        await LocalStore.stampCleared([id], cut);
      }
      if (ours != null && _same(ours.toMap(), merged.toMap())) continue;
      brought++;
      await LocalStore.writeHabit(merged);
      if (newer) await _adopt(id, stamps[id]);
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

  static int? _later(int? a, int? b) =>
      a == null ? b : (b == null || a >= b ? a : b);

  static Map<String, Completion> _since(
    Map<String, Completion> days,
    int? cut,
    int? known,
  ) {
    if (cut == null || cut == known) return days;
    final end = DateTime.fromMillisecondsSinceEpoch(cut);
    final last = DateTime(end.year, end.month, end.day);
    return {
      for (final entry in days.entries)
        if (entry.value.day?.isAfter(last) ?? true) entry.key: entry.value,
    };
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
      final kept = other.count > mine.count ||
              (other.count == mine.count &&
                  other.marks.length > mine.marks.length)
          ? other
          : mine;
      final spare = identical(kept, mine) ? other : mine;
      out[entry.key] = Completion(
        date: kept.date,
        count: kept.count,
        hour: kept.hour ?? spare.hour,
        minute: kept.hour != null ? kept.minute : spare.minute,
        marks: kept.marks,
        steps: {...mine.steps, ...other.steps},
        spent: kept.spent > 0 ? kept.spent : spare.spent,
      );
    }
    return out;
  }

  static bool _same(Map<String, dynamic> a, Map<String, dynamic> b) =>
      json.encode(a) == json.encode(b);

  static String _name(File file) => file.uri.pathSegments.last;
}
