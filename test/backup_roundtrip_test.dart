import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/vault_writer.dart';

import 'support/app_harness.dart';

Habit _habit(int i) => testHabit(
      id: 'h$i',
      name: 'Habit $i',
      order: i,
      color: Color(0xFF000000 + i * 977),
      kind: HabitKind.values[i % HabitKind.values.length],
      perDayTarget: i.isEven ? 1 : 3,
      unitLabel: i.isEven ? '' : 'glasses',
      category: i % 3 == 0 ? 'Health' : '',
      done: lastDays(i % 9),
      substeps: i % 4 == 0
          ? const [Substep(id: 's1', title: 'One'), Substep(id: 's2', title: 'Two')]
          : const [],
    );

Future<void> _seedEverything(int count) async {
  for (var i = 0; i < count; i++) {
    await LocalStore.writeHabit(_habit(i));
  }
  await LocalStore.writeCategory(
    Category(
      id: 'c1',
      name: 'Health',
      color: const Color(0xFF34D399),
      icon: 'heart',
    ),
  );
  for (var i = 0; i < 12; i++) {
    await LocalStore.writeNote(
      HabitNote(
        id: 'n$i',
        habitId: 'h${i % count}',
        date: AppClock.now().subtract(Duration(days: i)).dayKey,
        type: NoteType.values[i % NoteType.values.length],
        text: 'Note $i',
        photos: i.isEven ? const ['a.jpg'] : const [],
        createdAt: AppClock.now().subtract(Duration(days: i)),
      ),
    );
    await LocalStore.writeFocusSession(
      FocusSession(
        id: 'f$i',
        habitId: 'h${i % count}',
        targetMinutes: 25,
        seconds: 1500 + i,
        completed: true,
        startedAt: AppClock.now().subtract(Duration(days: i)),
      ),
    );
    await LocalStore.writeTodo(
      Todo(id: 't$i', text: 'Todo $i', createdAt: AppClock.now()),
    );
  }
}

String _exportedPayload(List<Habit> habits) {
  final payload = {
    'app': 'streak',
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'habits': habits.map((h) => h.toMap()).toList(),
    'notes': LocalStore.readNotes().map((n) => n.toMap()).toList(),
    'focus': LocalStore.readFocusSessions().map((f) => f.toMap()).toList(),
    'todos': LocalStore.readTodos().map((t) => t.toMap()).toList(),
    'categories': LocalStore.readCategories().map((c) => c.toMap()).toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

void main() {
  useEmptyStore();

  test('a full backup survives a round trip with nothing lost', () async {
    await _seedEverything(40);
    final before = LocalStore.readHabits();
    final raw = _exportedPayload(before.values.toList());

    final data = BackupService.parse(raw);

    expect(data.skipped, 0);
    expect(data.habits.length, before.length);
    expect(data.notes.length, 12);
    expect(data.focus.length, 12);
    expect(data.todos.length, 12);
    expect(data.categories.length, 1);

    for (final habit in data.habits) {
      final original = before[habit.id]!;
      expect(habit.name, original.name);
      expect(habit.kind, original.kind);
      expect(habit.color.toARGB32(), original.color.toARGB32());
      expect(habit.perDayTarget, original.perDayTarget);
      expect(habit.unitLabel, original.unitLabel);
      expect(habit.category, original.category);
      expect(habit.order, original.order);
      expect(habit.substeps.map((s) => s.id), original.substeps.map((s) => s.id));
      expect(habit.completions.keys.toSet(), original.completions.keys.toSet());
      for (final entry in original.completions.entries) {
        expect(habit.completions[entry.key]!.count, entry.value.count);
      }
    }
  });

  test('every field of every record survives, not just the counts', () async {
    await _seedEverything(20);
    final raw = _exportedPayload(LocalStore.readHabits().values.toList());
    final data = BackupService.parse(raw);

    Map<String, dynamic> byId(List<Map<String, dynamic>> maps, String id) =>
        maps.firstWhere((m) => m['id'] == id);

    final habits = [
      for (final h in LocalStore.readHabits().values) h.toMap(),
    ];
    for (final habit in data.habits) {
      expect(
        json.encode(habit.toMap()),
        json.encode(byId(habits, habit.id)),
        reason: 'habit ${habit.id} changed through the round trip',
      );
    }

    final notes = [for (final n in LocalStore.readNotes()) n.toMap()];
    for (final note in data.notes) {
      expect(json.encode(note.toMap()), json.encode(byId(notes, note.id)));
    }

    final sessions = [
      for (final f in LocalStore.readFocusSessions()) f.toMap(),
    ];
    for (final session in data.focus) {
      expect(
        json.encode(session.toMap()),
        json.encode(byId(sessions, session.id)),
      );
    }

    final todos = [for (final t in LocalStore.readTodos()) t.toMap()];
    for (final todo in data.todos) {
      expect(json.encode(todo.toMap()), json.encode(byId(todos, todo.id)));
    }

    final categories = [
      for (final c in LocalStore.readCategories()) c.toMap(),
    ];
    for (final category in data.categories) {
      expect(
        json.encode(category.toMap()),
        json.encode(byId(categories, category.id)),
      );
    }
  });

  test('two hundred habits round trip without losing one', () async {
    await _seedEverything(200);
    final raw = _exportedPayload(LocalStore.readHabits().values.toList());

    final data = BackupService.parse(raw);

    expect(data.habits.length, 200);
    expect(data.skipped, 0);
    expect(data.habits.map((h) => h.id).toSet().length, 200);
  });

  test('a backup restores into an app that has no data at all', () async {
    await _seedEverything(15);
    final raw = _exportedPayload(LocalStore.readHabits().values.toList());

    await LocalStore.wipeContent();
    expect(LocalStore.readHabits(), isEmpty);
    expect(LocalStore.readNotes(), isEmpty);

    final data = BackupService.parse(raw);
    for (final habit in data.habits) {
      await LocalStore.writeHabit(habit);
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
    for (final category in data.categories) {
      await LocalStore.writeCategory(category);
    }

    expect(LocalStore.readHabits().length, 15);
    expect(LocalStore.readNotes().length, 12);
    expect(LocalStore.readFocusSessions().length, 12);
    expect(LocalStore.readTodos().length, 12);
    expect(LocalStore.readCategories().length, 1);
  });

  test('restoring twice in a row lands on the same data, not double', () async {
    await _seedEverything(10);
    final raw = _exportedPayload(LocalStore.readHabits().values.toList());

    for (var round = 0; round < 2; round++) {
      final data = BackupService.parse(raw);
      await LocalStore.wipeContent();
      for (final habit in data.habits) {
        await LocalStore.writeHabit(habit);
      }
      for (final note in data.notes) {
        await LocalStore.writeNote(note);
      }
    }

    expect(LocalStore.readHabits().length, 10);
    expect(LocalStore.readNotes().length, 12);
  });

  test('a plain list of habits, the old format, still imports', () {
    final raw = json.encode([_habit(1).toMap(), _habit(2).toMap()]);
    final data = BackupService.parse(raw);

    expect(data.habits.length, 2);
    expect(data.notes, isEmpty);
  });

  test('one broken habit is skipped and counted, the rest survive', () {
    final raw = json.encode({
      'habits': [
        _habit(1).toMap(),
        {'nope': true},
        _habit(2).toMap(),
      ],
      'notes': [
        {'garbage': 1},
      ],
    });

    final data = BackupService.parse(raw);

    expect(data.habits.length, 2);
    expect(data.skipped, 2);
  });

  test('junk and empty files are rejected instead of wiping anything', () {
    expect(() => BackupService.parse('not json'), throwsException);
    expect(() => BackupService.parse('{}'), throwsException);
    expect(() => BackupService.parse('[]'), throwsException);
    expect(
      () => BackupService.parse(json.encode({'habits': []})),
      throwsException,
    );
  });

  test('the automatic backup drops the json and the readable copy', () async {
    await _seedEverything(5);
    final dir = await Directory.systemTemp.createTemp('streak_auto');
    addTearDown(() => dir.deleteSync(recursive: true));

    final path = await BackupService.runAuto(folder: dir.path);

    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    expect(BackupService.parse(File(path).readAsStringSync()).habits, hasLength(5));

    final vault = '${dir.path}/$vaultFolder';
    expect(File('$vault/README.md').existsSync(), isTrue);
    expect(File('$vault/habits/Habit 0.md').existsSync(), isTrue);
    expect(File('$vault/tasks.md').existsSync(), isTrue);
    expect(File('$vault/notes.md').existsSync(), isTrue);
    expect(File('$vault/focus.md').existsSync(), isTrue);
  });

  test('a completion keeps its steps, hour and amount through the trip', () {
    final day = AppClock.now().dayKey;
    final habit = testHabit(id: 'x', name: 'X').copyWith(
      completions: {
        day: Completion(
          date: day,
          count: 4.5,
          hour: 17,
          steps: const {'s1', 's2'},
        ),
      },
    );

    final data = BackupService.parse(json.encode({
      'habits': [habit.toMap()],
    }));

    final entry = data.habits.single.completions[day]!;
    expect(entry.count, 4.5);
    expect(entry.hour, 17);
    expect(entry.steps, {'s1', 's2'});
  });
}
