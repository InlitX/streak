import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/services/vault_writer.dart';

import 'support/app_harness.dart';

Future<Directory> _vault(List<Habit> habits, {List<Category> categories = const []}) async {
  final dir = await Directory.systemTemp.createTemp('streak_vault');
  addTearDown(() => dir.deleteSync(recursive: true));
  await VaultWriter.write(
    dir,
    habits: habits,
    categories: categories,
    notes: const [],
    todos: const [],
    focus: const [],
  );
  return dir;
}

String _read(Directory dir, String path) =>
    File('${dir.path}/$path').readAsStringSync();

List<File> _pages(Directory dir) => Directory('${dir.path}/habits')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.md'))
    .toList();

void main() {
  group('the readable copy', () {
    test('writes one file per habit, named after it', () async {
      final dir = await _vault([
        testHabit(id: 'a', name: 'Read 20 pages', done: lastDays(2)),
        testHabit(id: 'b', name: 'Meditate', order: 1),
      ]);

      expect(File('${dir.path}/habits/Read 20 pages.md').existsSync(), isTrue);
      expect(File('${dir.path}/habits/Meditate.md').existsSync(), isTrue);
      expect(File('${dir.path}/README.md').existsSync(), isTrue);
    });

    test('a name that cannot be a filename is cleaned up', () async {
      final dir = await _vault([
        testHabit(id: 'a', name: 'Gym / Cardio: 5k?'),
      ]);

      final files = _pages(dir);
      expect(files, hasLength(1));
      expect(files.single.path, endsWith('Gym Cardio 5k.md'));
      expect(_read(dir, 'habits/Gym Cardio 5k.md'), contains('Gym / Cardio: 5k?'));
    });

    test('two habits with the same name do not overwrite each other', () async {
      final dir = await _vault([
        testHabit(id: 'a', name: 'Walk', done: lastDays(1)),
        testHabit(id: 'b', name: 'Walk', order: 1),
      ]);

      expect(_pages(dir), hasLength(2));
      expect(_read(dir, 'habits/Walk.md'), contains('id: "a"'));
      expect(_read(dir, 'habits/Walk (2).md'), contains('id: "b"'));
    });

    test('a negative habit lists relapses, not wins', () async {
      final dir = await _vault([
        testHabit(
          id: 'a',
          name: 'No sugar',
          kind: HabitKind.negative,
          done: lastDays(1),
        ),
      ]);

      final text = _read(dir, 'habits/No sugar.md');
      expect(text, contains('type: avoid'));
      expect(text, contains('| Relapse |'));
      expect(text, isNot(contains('| Done |')));
    });

    test('an amount habit shows the number and its unit', () async {
      final dir = await _vault([
        testHabit(
          id: 'a',
          name: 'Water',
          kind: HabitKind.quantitative,
          perDayTarget: 8,
          unitLabel: 'glasses',
          done: lastDays(1),
        ),
      ]);

      final text = _read(dir, 'habits/Water.md');
      expect(text, contains('type: amount'));
      expect(text, contains('target: 8'));
      expect(text, contains('unit: "glasses"'));
      expect(text, contains('glasses |'));
    });

    test('the category name is written, not its id', () async {
      final dir = await _vault(
        [testHabit(id: 'a', name: 'Run', category: 'c1')],
        categories: [
          Category(
            id: 'c1',
            name: 'Health',
            color: const Color(0xFF34D399),
            icon: 'heart',
          ),
        ],
      );

      expect(_read(dir, 'habits/Run.md'), contains('category: "Health"'));
    });

    test('steps and dates come out readable', () async {
      final dir = await _vault([
        testHabit(
          id: 'a',
          name: 'Morning',
          substeps: const [
            Substep(id: 's1', title: 'Water'),
            Substep(id: 's2', title: 'Stretch'),
          ],
          done: [DateTime(2026, 3, 7)],
        ),
      ]);

      final text = _read(dir, 'habits/Morning.md');
      expect(text, contains('- Water'));
      expect(text, contains('- Stretch'));
      expect(text, contains('| 2026-03-07 | Sat |'));
    });

    test('archived habits go to their own folder', () async {
      final dir = await _vault([
        testHabit(id: 'a', name: 'Alive'),
        testHabit(id: 'b', name: 'Retired')
            .copyWith(archivedAt: DateTime(2026, 2, 1)),
      ]);

      expect(File('${dir.path}/habits/Alive.md').existsSync(), isTrue);
      expect(
        File('${dir.path}/habits/archived/Retired.md').existsSync(),
        isTrue,
      );
      expect(File('${dir.path}/habits/Retired.md').existsSync(), isFalse);
    });

    test('a renamed habit does not leave its old file behind', () async {
      final dir = await _vault([testHabit(id: 'a', name: 'Old name')]);
      expect(File('${dir.path}/habits/Old name.md').existsSync(), isTrue);

      await VaultWriter.write(
        dir,
        habits: [testHabit(id: 'a', name: 'New name')],
        categories: const [],
        notes: const [],
        todos: const [],
        focus: const [],
      );

      expect(File('${dir.path}/habits/New name.md').existsSync(), isTrue);
      expect(File('${dir.path}/habits/Old name.md').existsSync(), isFalse);
    });

    test('it never deletes a file it did not write', () async {
      final dir = await _vault([testHabit(id: 'a', name: 'Mine')]);
      final theirs = File('${dir.path}/habits/My own notes.md')
        ..writeAsStringSync('# Notes I keep here\n');

      await VaultWriter.write(
        dir,
        habits: const [],
        categories: const [],
        notes: const [],
        todos: const [],
        focus: const [],
      );

      expect(theirs.existsSync(), isTrue);
      expect(theirs.readAsStringSync(), '# Notes I keep here\n');
      expect(File('${dir.path}/habits/Mine.md').existsSync(), isFalse);
    });
  });
}
