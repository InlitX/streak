import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/import_service.dart';

List<int> _b(String s) => utf8.encode(s);

Habit _byName(ImportOutcome o, String name) =>
    o.habits.firstWhere((h) => h.name == name);

void main() {
  group('HabitBull CSV', () {
    final csv = '''
HabitName,HabitDescription,HabitCategory,DateNumber,Date,Value,CommentText
Read,Books,Learning,1,2024-01-01,1,
Read,Books,Learning,2,2024-01-02,1,
Run,,Health,1,2024-01-01,1,
Run,,Health,3,2024-01-03,0,
''';

    test('imports habits and skips zero-value days', () {
      final o = ImportService.parseBytes(_b(csv), fileName: 'habitbull.csv');
      expect(o.source, 'HabitBull');
      expect(o.habits.length, 2);
      final read = _byName(o, 'Read');
      final run = _byName(o, 'Run');
      expect(read.completions.length, 2);
      expect(run.completions.length, 1); // the 0-value day is skipped
      expect(o.entries, 3);
    });

    test('backdates createdAt so old days count', () {
      final o = ImportService.parseBytes(_b(csv), fileName: 'habitbull.csv');
      final read = _byName(o, 'Read');
      expect(read.createdAt, DateTime(2024, 1, 1));
      expect(read.isCompletedOn(DateTime(2024, 1, 1)), isTrue);
      expect(read.isCompletedOn(DateTime(2024, 1, 2)), isTrue);
      expect(read.kind, HabitKind.positive);
      expect(read.perDayTarget, 1);
    });
  });

  group('Loop Habit Tracker', () {
    const checkmarks = '''
Date,Meditate,Exercise
2024-01-01,2,0
2024-01-02,2,-1
2024-01-03,0,2
''';

    test('parses a loose Checkmarks.csv', () {
      final o =
          ImportService.parseBytes(_b(checkmarks), fileName: 'Checkmarks.csv');
      expect(o.source, 'Loop Habit Tracker');
      expect(_byName(o, 'Meditate').completions.length, 2);
      expect(_byName(o, 'Exercise').completions.length, 1);
    });

    test('parses a zipped CSV export', () {
      final archive = Archive()
        ..addFile(ArchiveFile(
            'Habits.csv', 0, _b('Position,Name\n1,Meditate\n2,Exercise\n')))
        ..addFile(ArchiveFile(
            'Checkmarks.csv', checkmarks.length, _b(checkmarks)));
      final zipped = ZipEncoder().encode(archive)!;

      final o = ImportService.parseBytes(zipped, fileName: 'Loop Habits.zip');
      expect(o.source, 'Loop Habit Tracker');
      expect(o.habits.length, 2);
      final med = _byName(o, 'Meditate');
      expect(med.createdAt, DateTime(2024, 1, 1));
      expect(med.isCompletedOn(DateTime(2024, 1, 2)), isTrue);
      expect(med.isCompletedOn(DateTime(2024, 1, 3)), isFalse); // value 0
    });

    test('imports habits from Habits.csv even with zero history', () {
      // Mirrors a real Loop export of freshly-created habits: Habits.csv lists
      // them, the top-level Checkmarks.csv is a header-only matrix.
      final archive = Archive()
        ..addFile(ArchiveFile(
            'Habits.csv',
            0,
            _b('Position,Name,Type,Color\n'
                '001,Cgf,YES_NO,#1976D2\n'
                '002,Fggg,NUMERICAL,#E53935\n')))
        ..addFile(ArchiveFile('Checkmarks.csv', 0, _b('Date,Cgf,Fggg,\n')))
        ..addFile(ArchiveFile(
            '001 Cgf/Checkmarks.csv', 0, _b('Date,Value,Notes\n')));
      final zipped = ZipEncoder().encode(archive)!;

      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');
      expect(o.source, 'Loop Habit Tracker');
      expect(o.habits.length, 2);
      expect(o.entries, 0);
      // Colour comes from Habits.csv.
      expect(_byName(o, 'Cgf').color.toARGB32(), 0xFF1976D2);
      expect(_byName(o, 'Fggg').color.toARGB32(), 0xFFE53935);
    });

    test('attaches per-habit Checkmarks when the matrix is empty', () {
      final archive = Archive()
        ..addFile(ArchiveFile(
            'Habits.csv', 0, _b('Position,Name\n001,Cgf\n')))
        ..addFile(ArchiveFile('Checkmarks.csv', 0, _b('Date,Cgf,\n')))
        ..addFile(ArchiveFile('001 Cgf/Checkmarks.csv', 0,
            _b('Date,Value,Notes\n2024-01-01,2,\n2024-01-02,2,\n')));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');
      expect(_byName(o, 'Cgf').completions.length, 2);
    });

    test('a NUMERICAL habit imports as measurable with its target', () {
      final archive = Archive()
        ..addFile(ArchiveFile(
            'Habits.csv',
            0,
            _b('Position,Name,Type,Unit,Target Type,Target Value\n'
                '001,Water,NUMERICAL,glasses,AT_LEAST,8\n')))
        ..addFile(ArchiveFile('Checkmarks.csv', 0, _b('Date,Water\n'
            '2024-03-01,8\n2024-03-02,3\n')));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');
      final w = _byName(o, 'Water');
      expect(w.kind, HabitKind.quantitative);
      expect(w.perDayTarget, 8);
      expect(w.unitLabel, 'glasses');
      expect(w.isCompletedOn(DateTime(2024, 3, 1)), isTrue); // 8 >= 8
      expect(w.isCompletedOn(DateTime(2024, 3, 2)), isFalse); // 3 < 8
    });

    test('prefers the top-level Checkmarks.csv over per-habit ones', () {
      final archive = Archive()
        ..addFile(ArchiveFile('001 Meditate/Checkmarks.csv', 0,
            _b('Date,Meditate\n2024-01-01,2\n')))
        ..addFile(
            ArchiveFile('Checkmarks.csv', checkmarks.length, _b(checkmarks)));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');
      expect(o.habits.length, 2); // used the top-level, 2-column file
    });
  });

  group('HabitKit JSON', () {
    String hk({int perDay = 1}) => json.encode({
          'habits': [
            {'id': 'a', 'name': 'Ytyy', 'color': 'blue', 'archived': false},
            {'id': 'b', 'name': 'Cgg', 'color': 'red', 'archived': false},
            {'id': 'z', 'name': 'Old', 'color': 'green', 'archived': true},
          ],
          'completions': [
            {
              'date': '2026-07-21T22:00:00.000Z',
              'habitId': 'a',
              'timezoneOffsetInMinutes': 120,
              'amountOfCompletions': 1,
            },
            {
              'date': '2026-07-20T22:00:00.000Z',
              'habitId': 'b',
              'timezoneOffsetInMinutes': 120,
              'amountOfCompletions': 3,
            },
            {'date': 'x', 'habitId': 'zzz', 'amountOfCompletions': 1},
          ],
          'intervals': [
            {'habitId': 'b', 'requiredNumberOfCompletionsPerDay': perDay},
          ],
        });

    test('imports habits + completions, skips archived, maps colours', () {
      final o = ImportService.parseBytes(_b(hk()), fileName: 'habitkit.json');
      expect(o.source, 'HabitKit');
      expect(o.habits.length, 2); // archived 'Old' skipped
      expect(_byName(o, 'Ytyy').color.toARGB32(), 0xFF2196F3);
      expect(_byName(o, 'Cgg').color.toARGB32(), 0xFFF44336);
    });

    test('shifts UTC completion to the local calendar day', () {
      final o = ImportService.parseBytes(_b(hk()), fileName: 'habitkit.json');
      // 2026-07-21T22:00Z + 120min → 2026-07-22.
      expect(_byName(o, 'Ytyy')
          .completions
          .containsKey(DateTime(2026, 7, 22).dayKey), isTrue);
    });

    test('an interval target > 1 imports as a measurable habit', () {
      final o = ImportService.parseBytes(_b(hk(perDay: 3)), fileName: 'x.json');
      final cgg = _byName(o, 'Cgg');
      expect(cgg.kind, HabitKind.quantitative);
      expect(cgg.perDayTarget, 3);
    });
  });

  group('Habitica JSON', () {
    final jsonStr = json.encode({
      'tasks': [
        {
          'type': 'daily',
          'text': 'Water',
          'history': [
            {'date': 1704067200000, 'value': 1, 'completed': true},
            {'date': 1704153600000, 'value': 0, 'completed': false},
          ],
        },
        {
          'type': 'habit',
          'text': 'Pushups',
          'history': [
            {'date': 1704067200000, 'value': 0},
            {'date': 1704153600000, 'value': 1}, // value rose → done that day
          ],
        },
        {'type': 'todo', 'text': 'ignored'},
      ],
    });

    test('imports dailies and habits, ignores todos', () {
      final o = ImportService.parseBytes(_b(jsonStr), fileName: 'user.json');
      expect(o.source, 'Habitica');
      expect(o.habits.length, 2);
      expect(_byName(o, 'Water').completions.length, 1); // only the completed day
      expect(_byName(o, 'Pushups').completions.length, 1); // only the rise
    });

    test('supports the data.tasks nesting', () {
      final nested = json.encode({
        'data': {
          'tasks': [
            {
              'type': 'daily',
              'text': 'X',
              'history': [
                {'date': 1704067200000, 'completed': true},
              ],
            },
          ],
        },
      });
      final o = ImportService.parseBytes(_b(nested), fileName: 'user.json');
      expect(o.habits.length, 1);
    });
  });

  group('Generic CSV', () {
    test('date-matrix with semicolons and truthy strings', () {
      const csv = 'Timestamp;Leer;Correr\n'
          '2024-01-01;x;\n'
          '2024-01-02;yes;1\n'
          '2024-01-03;;true\n';
      final o = ImportService.parseBytes(_b(csv), fileName: 'export.csv');
      expect(o.source, 'CSV');
      expect(_byName(o, 'Leer').completions.length, 2); // 01, 02
      expect(_byName(o, 'Correr').completions.length, 2); // 02, 03
    });

    test('long/tidy format (habit,date,value)', () {
      const csv = 'habit,date,value\n'
          'Yoga,2024-02-01,1\n'
          'Yoga,2024-02-02,1\n'
          'Yoga,2024-02-03,0\n';
      final o = ImportService.parseBytes(_b(csv), fileName: 'tidy.csv');
      expect(o.source, 'CSV');
      expect(o.habits.length, 1);
      expect(_byName(o, 'Yoga').completions.length, 2);
    });

    test('parses dd/MM/yyyy and MM/dd/yyyy day-first-safely', () {
      const csv = 'Date,A\n'
          '31/01/2024,1\n' // clearly dd/MM
          '01/02/2024,1\n'; // ambiguous → day-first
      final o = ImportService.parseBytes(_b(csv), fileName: 'x.csv');
      final a = _byName(o, 'A');
      expect(a.completions.containsKey(DateTime(2024, 1, 31).dayKey), isTrue);
      expect(a.completions.containsKey(DateTime(2024, 2, 1).dayKey), isTrue);
    });
  });

  group('errors', () {
    test('empty CSV throws a friendly error', () {
      expect(
        () => ImportService.parseBytes(_b('Date,A\n'), fileName: 'x.csv'),
        throwsA(isA<ImportException>()),
      );
    });

    test('.db files are rejected with guidance', () {
      // parseBytes doesn't see the extension guard (that's in pickAndParse),
      // but random binary should not crash — it should throw ImportException.
      expect(
        () => ImportService.parseBytes([0x00, 0x01, 0x02, 0x03]),
        throwsA(isA<ImportException>()),
      );
    });
  });
}
