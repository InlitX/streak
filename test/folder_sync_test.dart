import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/folder_sync.dart';

import 'support/app_harness.dart';

final _monday = DateTime(2026, 3, 2);
final _tuesday = DateTime(2026, 3, 3);

Habit _run({List<DateTime> done = const []}) => testHabit(
      id: 'run',
      name: 'Run',
      done: done,
      daysOld: 400,
    );

Future<Directory> _folder() async {
  final dir = await Directory.systemTemp.createTemp('streak_sync');
  addTearDown(() => dir.deleteSync(recursive: true));
  await LocalStore.writeSetting('autoBackupFolder', dir.path);
  return dir;
}

Future<void> _drop(
  Directory dir,
  List<Habit> habits, {
  required DateTime at,
  String stamp = '2026-03-03_10-00-00',
}) async {
  final payload = {
    'app': 'streak',
    'version': 1,
    'exportedAt': at.toIso8601String(),
    'habits': habits.map((h) => h.toMap()).toList(),
  };
  File('${dir.path}/streak_backup_$stamp.json')
      .writeAsStringSync(json.encode(payload));
}

void main() {
  useEmptyStore();

  group('merging days', () {
    test('a day only the other device has is brought in', () {
      final merged = FolderSync.mergeCompletions(
        {'02-03-2026': const Completion(date: '02-03-2026')},
        {'03-03-2026': const Completion(date: '03-03-2026')},
      );
      expect(merged.keys, containsAll(['02-03-2026', '03-03-2026']));
    });

    test('a day only this device has is never dropped', () {
      final merged = FolderSync.mergeCompletions(
        {'02-03-2026': const Completion(date: '02-03-2026')},
        const {},
      );
      expect(merged.keys, contains('02-03-2026'));
    });

    test('when both logged the same day the bigger amount wins', () {
      final merged = FolderSync.mergeCompletions(
        {'02-03-2026': const Completion(date: '02-03-2026', count: 20)},
        {'02-03-2026': const Completion(date: '02-03-2026', count: 8)},
      );
      expect(merged['02-03-2026']!.count, 20);
    });

    test('checklist steps from both sides are kept', () {
      final merged = FolderSync.mergeCompletions(
        {
          '02-03-2026': const Completion(date: '02-03-2026', steps: {'s1'}),
        },
        {
          '02-03-2026': const Completion(date: '02-03-2026', steps: {'s2'}),
        },
      );
      expect(merged['02-03-2026']!.steps, {'s1', 's2'});
    });
  });

  group('reading the folder', () {
    test('nothing older than what we already took is read again', () async {
      final dir = await _folder();
      await _drop(dir, [_run()], at: DateTime(2026, 3, 3, 10));

      expect(FolderSync.incoming(dir, DateTime(2026, 3, 4)), isNull);
      expect(FolderSync.incoming(dir, DateTime(2026, 3, 2)), isNotNull);
    });

    test('a broken file does not stop the older good one', () async {
      final dir = await _folder();
      await _drop(dir, [_run()],
          at: DateTime(2026, 3, 3, 10), stamp: '2026-03-03_10-00-00');
      File('${dir.path}/streak_backup_2026-03-04_10-00-00.json')
          .writeAsStringSync('{ this is not json');

      final data = FolderSync.incoming(dir, null);
      expect(data, isNotNull);
      expect(data!.habits.single.id, 'run');
    });

    test('an empty folder is simply nothing to do', () async {
      final dir = await _folder();
      expect(FolderSync.incoming(dir, null), isNull);
      expect(await FolderSync.pull(), 0);
    });
  });

  group('pulling', () {
    test('the other device\'s day arrives and ours stays', () async {
      final dir = await _folder();
      await LocalStore.writeHabit(_run(done: [_tuesday]));
      await _drop(dir, [_run(done: [_monday])], at: DateTime(2026, 3, 3, 10));

      expect(await FolderSync.pull(), 1);

      final after = LocalStore.readHabits()['run']!;
      expect(after.completions.keys, containsAll([
        _monday.dayKey,
        _tuesday.dayKey,
      ]));
    });

    test('a habit only this device has is left alone', () async {
      final dir = await _folder();
      await LocalStore.writeHabit(_run(done: [_tuesday]));
      await LocalStore.writeHabit(testHabit(id: 'mine', name: 'Only here'));
      await _drop(dir, [_run(done: [_monday])], at: DateTime(2026, 3, 3, 10));

      await FolderSync.pull();

      expect(LocalStore.readHabits()['mine'], isNotNull);
      expect(LocalStore.readHabits()['mine']!.name, 'Only here');
    });

    test('a habit only the other device has is created here', () async {
      final dir = await _folder();
      await _drop(
        dir,
        [testHabit(id: 'theirs', name: 'From the tablet')],
        at: DateTime(2026, 3, 3, 10),
      );

      expect(await FolderSync.pull(), 1);
      expect(LocalStore.readHabits()['theirs']!.name, 'From the tablet');
    });

    test('pulling twice does not do the work twice', () async {
      final dir = await _folder();
      await LocalStore.writeHabit(_run(done: [_tuesday]));
      await _drop(dir, [_run(done: [_monday])], at: DateTime(2026, 3, 3, 10));

      expect(await FolderSync.pull(), 1);
      expect(await FolderSync.pull(), 0);
    });

    test('an unchanged habit is not counted as a change', () async {
      final dir = await _folder();
      final habit = _run(done: [_monday]);
      await LocalStore.writeHabit(habit);
      await _drop(dir, [habit], at: DateTime(2026, 3, 3, 10));

      expect(await FolderSync.pull(), 0);
    });

    test('with no folder set it does nothing at all', () async {
      await LocalStore.writeSetting('autoBackupFolder', '');
      await LocalStore.writeHabit(_run(done: [_tuesday]));

      expect(await FolderSync.pull(), 0);
      expect(LocalStore.readHabits()['run']!.completions, hasLength(1));
    });
  });
}
