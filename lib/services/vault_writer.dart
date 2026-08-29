import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_note.dart';
import 'package:streak/features/todos/data/todo.dart';

const vaultFolder = 'Streak';

class VaultWriter {
  const VaultWriter._();

  static const marker = 'generator: streak';

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static Future<void> write(
    Directory root, {
    required List<Habit> habits,
    required List<Category> categories,
    required List<HabitNote> notes,
    required List<Todo> todos,
    required List<FocusSession> focus,
  }) async {
    final names = <String, String>{};
    for (final habit in habits) {
      names[habit.id] = habit.name;
    }
    final labels = <String, String>{};
    for (final category in categories) {
      labels[category.id] = category.name;
    }

    final live = habits.where((h) => !h.isArchived).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final archived = habits.where((h) => h.isArchived).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    await _writeText(root, 'README.md', _readme(habits, todos, notes, focus));
    await _writeHabits(Directory('${root.path}/habits'), live, labels);
    await _writeHabits(
      Directory('${root.path}/habits/archived'),
      archived,
      labels,
    );
    await _writeText(root, 'tasks.md', _tasks(todos));
    await _writeText(root, 'notes.md', _notes(notes, names));
    await _writeText(root, 'focus.md', _focus(focus, names));
  }

  static Future<void> _writeHabits(
    Directory dir,
    List<Habit> habits,
    Map<String, String> categories,
  ) async {
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final taken = <String>{};
    final written = <String>{};
    for (final habit in habits) {
      final name = _unique(_slug(habit.name), taken);
      written.add('$name.md');
      await _writeText(dir, '$name.md', _habit(habit, categories));
    }
    _sweep(dir, written);
  }

  static void _sweep(Directory dir, Set<String> keep) {
    try {
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.md')) continue;
        final name = entity.uri.pathSegments.last;
        if (keep.contains(name)) continue;
        if (!_isOurs(entity)) continue;
        entity.deleteSync();
      }
    } catch (e) {
      debugPrint('Could not tidy the vault: $e');
    }
  }

  static bool _isOurs(File file) {
    try {
      return file.readAsStringSync().contains(marker);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _writeText(
    Directory dir,
    String name,
    String content,
  ) async {
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await File('${dir.path}/$name').writeAsString(content);
  }

  static String _readme(
    List<Habit> habits,
    List<Todo> todos,
    List<HabitNote> notes,
    List<FocusSession> focus,
  ) {
    final live = habits.where((h) => !h.isArchived).length;
    final archived = habits.length - live;
    return '''
# Streak

Everything Streak knows about your habits, written as plain files you can read
with any editor, or open as a vault in a notes app. Nothing here is encrypted or
packed: it is yours.

Written on ${_stamp(DateTime.now())}.

| What | How many |
| --- | --- |
| Habits | $live |
| Archived habits | $archived |
| Tasks | ${todos.length} |
| Notes | ${notes.length} |
| Focus sessions | ${focus.length} |

## What is in here

- `habits/` one file per habit, with its settings and its full day by day
  history. Archived ones are in `habits/archived/`.
- `tasks.md` your to-do list.
- `notes.md` the notes you wrote on habit days.
- `focus.md` every focus session, newest first.

Streak rewrites this folder on every automatic backup, so anything you add here
under a name of its own is left alone, but edits to these files are overwritten.

## Restoring

These files are for reading. What Streak restores from is the
`streak_backup_*.json` sitting in the folder above this one. To bring your data
back, use Settings > Data > Import backup and pick the newest of those. Editing
the markdown here does not change anything in the app.
''';
  }

  static String _habit(Habit habit, Map<String, String> categories) {
    final out = StringBuffer();
    final category = categories[habit.category] ?? '';

    out.writeln('---');
    out.writeln('name: ${_yaml(habit.name)}');
    out.writeln('id: ${_yaml(habit.id)}');
    out.writeln('type: ${_type(habit)}');
    if (habit.kind == HabitKind.quantitative) {
      out.writeln('target: ${formatAmount(habit.perDayTarget)}');
      if (habit.unitLabel.isNotEmpty) {
        out.writeln('unit: ${_yaml(habit.unitLabel)}');
      }
    }
    out.writeln('schedule: ${_yaml(_schedule(habit))}');
    if (category.isNotEmpty) out.writeln('category: ${_yaml(category)}');
    out.writeln('color: ${_yaml(_hex(habit.color.toARGB32()))}');
    out.writeln('created: ${_day(habit.createdAt)}');
    if (habit.isArchived) {
      out.writeln('archived: ${_day(habit.archivedAt!)}');
    }
    out.writeln(marker);
    out.writeln('---');
    out.writeln();
    out.writeln('# ${habit.name}');

    if (habit.description.trim().isNotEmpty) {
      out.writeln();
      out.writeln(habit.description.trim());
    }

    if (habit.substeps.isNotEmpty) {
      out.writeln();
      out.writeln('## Steps');
      out.writeln();
      for (final step in habit.substeps) {
        out.writeln('- ${step.title}');
      }
    }

    if (habit.reminders.isNotEmpty) {
      out.writeln();
      out.writeln('## Reminders');
      out.writeln();
      for (final reminder in habit.reminders) {
        final at = '${_pad(reminder.hour)}:${_pad(reminder.minute)}';
        final days = reminder.days.isEmpty
            ? 'every day'
            : (reminder.days.toList()..sort())
                .map((d) => _weekdays[d - 1])
                .join(', ');
        out.writeln('- $at on $days');
      }
    }

    if (habit.vacations.isNotEmpty) {
      out.writeln();
      out.writeln('## Breaks');
      out.writeln();
      for (final vacation in habit.vacations) {
        final end = vacation.end == null ? 'ongoing' : _day(vacation.end!);
        out.writeln('- ${_day(vacation.start)} to $end');
      }
    }

    out.writeln();
    out.writeln('## History');
    out.writeln();
    out.write(_history(habit));
    return out.toString();
  }

  static String _history(Habit habit) {
    final entries = habit.completions.values.toList()
      ..sort((a, b) => parseDayKey(b.date).compareTo(parseDayKey(a.date)));

    if (entries.isEmpty) return 'Nothing logged yet.\n';

    final negative = habit.kind == HabitKind.negative;
    final column = negative
        ? 'Relapse'
        : habit.kind == HabitKind.quantitative
            ? 'Amount'
            : 'Done';

    final out = StringBuffer()
      ..writeln('| Date | Day | $column |')
      ..writeln('| --- | --- | --- |');

    for (final entry in entries) {
      final date = parseDayKey(entry.date);
      final value = negative
          ? 'yes'
          : habit.kind == HabitKind.quantitative
              ? _amount(habit, entry.count)
              : 'yes';
      out.writeln(
        '| ${_day(date)} | ${_weekdays[date.weekday - 1]} | $value |',
      );
    }
    return out.toString();
  }

  static String _amount(Habit habit, double count) {
    if (habit.isTimeAmount) return formatMinutes(count);
    final value = formatAmount(count);
    return habit.unitLabel.isEmpty ? value : '$value ${habit.unitLabel}';
  }

  static String _tasks(List<Todo> todos) {
    if (todos.isEmpty) return '# Tasks\n\nNothing here yet.\n';

    final open = todos.where((t) => !t.done).toList();
    final done = todos.where((t) => t.done).toList();

    final out = StringBuffer()..writeln('# Tasks');
    out.writeln();
    out.writeln('${open.length} open, ${done.length} done.');

    void section(String title, List<Todo> list, bool checked) {
      if (list.isEmpty) return;
      out.writeln();
      out.writeln('## $title');
      out.writeln();
      for (final todo in list) {
        final box = checked ? '[x]' : '[ ]';
        final when = todo.date.isEmpty
            ? ''
            : ' (${_day(parseDayKey(todo.date))})';
        out.writeln('- $box ${todo.text}$when');
      }
    }

    section('Open', open, false);
    section('Done', done, true);
    return out.toString();
  }

  static String _notes(List<HabitNote> notes, Map<String, String> habits) {
    if (notes.isEmpty) return '# Notes\n\nNothing here yet.\n';

    final sorted = notes.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final out = StringBuffer()..writeln('# Notes');
    for (final note in sorted) {
      final habit = habits[note.habitId] ?? 'Unknown habit';
      final day = note.date.isEmpty ? '' : ' · ${_day(parseDayKey(note.date))}';
      out.writeln();
      out.writeln('## $habit$day');
      out.writeln();
      out.writeln(note.text.trim().isEmpty ? '(empty)' : note.text.trim());
    }
    return out.toString();
  }

  static String _focus(List<FocusSession> focus, Map<String, String> habits) {
    if (focus.isEmpty) return '# Focus\n\nNothing here yet.\n';

    final sorted = focus.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final total = sorted.fold<int>(0, (sum, s) => sum + s.seconds);
    final out = StringBuffer()
      ..writeln('# Focus')
      ..writeln()
      ..writeln(
        '${sorted.length} sessions, ${formatMinutes(total / 60)} in total.',
      )
      ..writeln()
      ..writeln('| Date | Habit | Length | Finished |')
      ..writeln('| --- | --- | --- | --- |');

    for (final session in sorted) {
      final habit = habits[session.habitId] ?? '';
      out.writeln(
        '| ${_stamp(session.startedAt)} | $habit '
        '| ${formatMinutes(session.seconds / 60)} '
        '| ${session.completed ? 'yes' : 'no'} |',
      );
    }
    return out.toString();
  }

  static String _type(Habit habit) => switch (habit.kind) {
        HabitKind.positive => habit.substeps.isEmpty ? 'habit' : 'checklist',
        HabitKind.negative => 'avoid',
        HabitKind.quantitative => 'amount',
      };

  static String _schedule(Habit habit) => switch (habit.interval) {
        HabitInterval.daily => 'every day',
        HabitInterval.weekly => '${habit.targetFrequency} times per week',
        HabitInterval.monthly => '${habit.targetFrequency} times per month',
        HabitInterval.weekdays => habit.scheduleWeekdays.isEmpty
            ? 'every day'
            : (habit.scheduleWeekdays.toList()..sort())
                .map((d) => _weekdays[d - 1])
                .join(', '),
        HabitInterval.everyXDays => 'every ${habit.scheduleEvery} days',
      };

  static String _slug(String name) {
    var clean = name;
    for (final bad in [
      r'\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
    ]) {
      clean = clean.replaceAll(bad, ' ');
    }
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (clean.endsWith('.')) {
      clean = clean.substring(0, clean.length - 1).trimRight();
    }
    if (clean.length > 60) clean = clean.substring(0, 60).trim();
    return clean.isEmpty ? 'habit' : clean;
  }

  static String _unique(String name, Set<String> taken) {
    final lower = name.toLowerCase();
    if (taken.add(lower)) return name;
    var index = 2;
    while (!taken.add('$lower ($index)')) {
      index++;
    }
    return '$name ($index)';
  }

  static String _yaml(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _day(DateTime date) =>
      '${date.year}-${_pad(date.month)}-${_pad(date.day)}';

  static String _stamp(DateTime date) =>
      '${_day(date)} ${_pad(date.hour)}:${_pad(date.minute)}';

  static String _pad(int value) => value < 10 ? '0$value' : '$value';
}
