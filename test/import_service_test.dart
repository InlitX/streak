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
      expect(run.completions.length, 1);
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

  group('a Loop database file', () {
    List<int> sqlite() => [
          ...'SQLite format 3'.codeUnits,
          0,
          ...List<int>.filled(200, 7),
        ];

    test('is refused with instructions even without a file name', () {
      expect(
        () => ImportService.parseBytes(sqlite()),
        throwsA(
          isA<ImportException>().having(
            (e) => e.message,
            'message',
            contains('Export as CSV'),
          ),
        ),
      );
    });

    test('is refused when it is named too', () {
      expect(
        () => ImportService.parseBytes(sqlite(), fileName: 'Loop Habits.db'),
        throwsA(isA<ImportException>()),
      );
    });

    test('a real csv is still not mistaken for one', () {
      final o = ImportService.parseBytes(
        _b('Date,Walk\n2026-03-02,1\n'),
        fileName: 'loop.csv',
      );
      expect(o.habits, hasLength(1));
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
      expect(med.isCompletedOn(DateTime(2024, 1, 3)), isFalse);
    });

    test('parses a Habit Builder backup', () {
      final day = DateTime(2024, 3, 5, 9).millisecondsSinceEpoch;
      final archive = Archive()
        ..addFile(ArchiveFile.string('habits.csv',
            'id,name,color,order,archived,notes\n1,Read,Red,1,false,\n2,Run,Blue,0,false,Morning\n'))
        ..addFile(ArchiveFile.string(
            'actions.csv', 'id,habit_id,timestamp\n1,1,$day\n2,2,$day\n3,1,$day\n'))
        ..addFile(ArchiveFile.string('metadata.txt', 'backup_version=1'));
      final zipped = ZipEncoder().encode(archive)!;

      final o = ImportService.parseBytes(zipped, fileName: 'backup.zip');
      expect(o.source, 'Habit Builder');
      expect(o.habits.map((h) => h.name), ['Run', 'Read']);
      expect(o.habits.first.description, 'Morning');
      expect(_byName(o, 'Read').isCompletedOn(DateTime(2024, 3, 5)), isTrue);
      expect(_byName(o, 'Read').isCompletedOn(DateTime(2024, 3, 6)), isFalse);
    });

    test('imports habits from Habits.csv even with zero history', () {
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
            '2024-03-01,8000\n2024-03-02,3000\n')));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');
      final w = _byName(o, 'Water');
      expect(w.kind, HabitKind.quantitative);
      expect(w.perDayTarget, 8);
      expect(w.unitLabel, 'glasses');
      expect(w.isCompletedOn(DateTime(2024, 3, 1)), isTrue);
      expect(w.isCompletedOn(DateTime(2024, 3, 2)), isFalse);
    });

    test('reads the current export: named values, thousandths and archived',
        () {
      final archive = Archive()
        ..addFile(ArchiveFile(
            'Habits.csv',
            0,
            _b('Position,Name,Type,Question,Description,FrequencyNumerator,'
                'FrequencyDenominator,Color,Unit,Target Type,Target Value,'
                'Archived?\n'
                '001,Read,YES_NO,,,1,1,#1976D2,,,,false\n'
                '002,Walk,NUMERICAL,,,1,1,#E53935,km,AT_LEAST,2.5,false\n'
                '003,Old,YES_NO,,,1,1,#43A047,,,,true\n')))
        ..addFile(ArchiveFile('Checkmarks.csv', 0, _b('Date,Read,Walk,Old,\n'
            '2024-03-03,YES_MANUAL,2750,UNKNOWN,\n'
            '2024-03-02,YES_AUTO,1250,YES_MANUAL,\n'
            '2024-03-01,SKIP,-1,NO,\n')));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');

      final read = _byName(o, 'Read');
      expect(read.completions.length, 1);
      expect(read.isCompletedOn(DateTime(2024, 3, 3)), isTrue);

      final walk = _byName(o, 'Walk');
      expect(walk.perDayTarget, 2.5);
      expect(walk.completions[DateTime(2024, 3, 3).dayKey]!.count, 2.75);
      expect(walk.isCompletedOn(DateTime(2024, 3, 3)), isTrue);
      expect(walk.isCompletedOn(DateTime(2024, 3, 2)), isFalse);

      expect(_byName(o, 'Old').isArchived, isTrue);
      expect(read.isArchived, isFalse);
    });

    test('brings frequency, question, notes and comma decimals', () {
      final archive = Archive()
        ..addFile(ArchiveFile(
            'Habits.csv',
            0,
            _b('Position,Name,Type,Question,Description,FrequencyNumerator,'
                'FrequencyDenominator,Color,Unit,Target Type,Target Value,'
                'Archived?\n'
                '001,Gym,YES_NO,Did you train?,Legs and back,3,7,#1976D2,,,,false\n'
                '002,Water,NUMERICAL,,,1,1,#E53935,l,AT_LEAST,"1,5",false\n'
                '003,Bills,YES_NO,,,1,30,#43A047,,,,false\n'
                '004,Plants,YES_NO,,,1,3,#43A047,,,,false\n')))
        ..addFile(ArchiveFile('001 Gym/Checkmarks.csv', 0,
            _b('Date,Value,Notes\n2024-03-02,YES_MANUAL,"Heavy day\nnew PR"\n'
                '2024-03-01,YES_AUTO,\n')))
        ..addFile(ArchiveFile('Checkmarks.csv', 0,
            _b('Date,Gym,Water,Bills,Plants,\n'
                '2024-03-02,YES_MANUAL,1500,NO,NO,\n'
                '2024-03-01,YES_MANUAL,0,NO,YES_MANUAL,\n')));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');

      final gym = _byName(o, 'Gym');
      expect(gym.interval, HabitInterval.weekly);
      expect(gym.targetFrequency, 3);
      expect(gym.description, 'Did you train?\nLegs and back');
      expect(gym.isCompletedOn(DateTime(2024, 3, 1)), isFalse);
      expect(gym.isCompletedOn(DateTime(2024, 3, 2)), isTrue);
      expect(o.notes.single.habitId, gym.id);
      expect(o.notes.single.date, DateTime(2024, 3, 2).dayKey);
      expect(o.notes.single.text, 'Heavy day\nnew PR');

      expect(_byName(o, 'Water').perDayTarget, 1.5);
      expect(_byName(o, 'Water').interval, HabitInterval.daily);
      expect(_byName(o, 'Bills').interval, HabitInterval.monthly);
      final plants = _byName(o, 'Plants');
      expect(plants.interval, HabitInterval.everyXDays);
      expect(plants.scheduleEvery, 3);
      expect(plants.isCompletedOn(DateTime(2024, 3, 1)), isTrue);
    });

    test('without Habits.csv the top-level Checkmarks.csv is used', () {
      final archive = Archive()
        ..addFile(ArchiveFile('001 Meditate/Checkmarks.csv', 0,
            _b('Date,Meditate\n2024-01-01,2\n')))
        ..addFile(
            ArchiveFile('Checkmarks.csv', checkmarks.length, _b(checkmarks)));
      final zipped = ZipEncoder().encode(archive)!;
      final o = ImportService.parseBytes(zipped, fileName: 'loop.zip');
      expect(o.habits.length, 2);
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
      expect(o.habits.length, 2);
      expect(_byName(o, 'Ytyy').color.toARGB32(), 0xFF2196F3);
      expect(_byName(o, 'Cgg').color.toARGB32(), 0xFFF44336);
    });

    test('shifts UTC completion to the local calendar day', () {
      final o = ImportService.parseBytes(_b(hk()), fileName: 'habitkit.json');
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

    test('hex colours import as themselves, in every notation', () {
      final raw = json.encode({
        'habits': [
          {'id': 'a', 'name': 'Hash', 'color': '#FF5722'},
          {'id': 'b', 'name': 'Bare', 'color': '4CAF50'},
          {'id': 'c', 'name': 'Prefixed', 'color': '0xFF2196F3'},
          {'id': 'd', 'name': 'Short', 'color': '#0F0'},
        ],
        'completions': [
          {'date': '2026-07-21T10:00:00.000Z', 'habitId': 'a'},
        ],
      });
      final o = ImportService.parseBytes(_b(raw), fileName: 'habitkit.json');

      expect(o.source, 'HabitKit');
      expect(_byName(o, 'Hash').color.toARGB32(), 0xFFFF5722);
      expect(_byName(o, 'Bare').color.toARGB32(), 0xFF4CAF50);
      expect(_byName(o, 'Prefixed').color.toARGB32(), 0xFF2196F3);
      expect(_byName(o, 'Short').color.toARGB32(), 0xFF00FF00);
    });

    test('a file with no completions yet still imports the habits', () {
      final raw = json.encode({
        'habits': [
          {'id': 'a', 'name': 'Fresh', 'color': 'blue', 'orderIndex': 0},
        ],
        'intervals': [
          {'habitId': 'a', 'requiredNumberOfCompletionsPerDay': 1},
        ],
      });
      final o = ImportService.parseBytes(_b(raw), fileName: 'habitkit.json');

      expect(o.source, 'HabitKit');
      expect(o.habits.single.name, 'Fresh');
      expect(o.entries, 0);
    });

    test('orderIndex decides the order, not the position in the file', () {
      final raw = json.encode({
        'habits': [
          {'id': 'a', 'name': 'Third', 'orderIndex': 2, 'iconName': 'x'},
          {'id': 'b', 'name': 'First', 'orderIndex': 0, 'iconName': 'x'},
          {'id': 'c', 'name': 'Second', 'orderIndex': 1, 'iconName': 'x'},
        ],
      });
      final o = ImportService.parseBytes(_b(raw), fileName: 'habitkit.json');

      expect(o.habits.map((h) => h.name), ['First', 'Second', 'Third']);
      expect(o.habits.map((h) => h.order), [0, 1, 2]);
    });

    test('an all-archived export says so instead of failing blankly', () {
      final raw = json.encode({
        'habits': [
          {'id': 'a', 'name': 'Old', 'archived': true},
        ],
        'completions': <dynamic>[],
      });

      expect(
        () => ImportService.parseBytes(_b(raw), fileName: 'habitkit.json'),
        throwsA(
          isA<ImportException>().having(
            (e) => e.message,
            'message',
            contains('archived'),
          ),
        ),
      );
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
            {'date': 1704153600000, 'value': 1},
          ],
        },
        {'type': 'todo', 'text': 'ignored'},
      ],
    });

    test('imports dailies and habits, ignores todos', () {
      final o = ImportService.parseBytes(_b(jsonStr), fileName: 'user.json');
      expect(o.source, 'Habitica');
      expect(o.habits.length, 2);
      expect(_byName(o, 'Water').completions.length, 1);
      expect(_byName(o, 'Pushups').completions.length, 1);
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
      expect(_byName(o, 'Leer').completions.length, 2);
      expect(_byName(o, 'Correr').completions.length, 2);
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
          '31/01/2024,1\n'
          '01/02/2024,1\n';
      final o = ImportService.parseBytes(_b(csv), fileName: 'x.csv');
      final a = _byName(o, 'A');
      expect(a.completions.containsKey(DateTime(2024, 1, 31).dayKey), isTrue);
      expect(a.completions.containsKey(DateTime(2024, 2, 1).dayKey), isTrue);
    });
  });

  group('Habitify CSV', () {
    final csv = '''
﻿Habit;Date;Total log;Unit;Status;Habit ID
Quit;2026-02-09;0;times;Succeeded;q1
Quit;2026-02-10;0;times;Succeeded;q1
Quit;2026-02-11;3;times;Failed;q1
Quit;2026-02-12;1;times;Failed;q1
Read;2026-02-10;1;times;Completed;r1
Read;2026-02-11;0;times;Skipped;r1
Read;2026-02-12;1;times;Completed;r1
''';

    test('reads Status: Failed is a relapse, Skipped is not done', () {
      final o = ImportService.parseBytes(_b(csv), fileName: 'habitify.csv');
      expect(o.source, 'Habitify');
      final quit = _byName(o, 'Quit');
      final read = _byName(o, 'Read');
      expect(quit.kind, HabitKind.negative);
      expect(quit.createdAt, DateTime(2026, 2, 9));
      expect(quit.isCompletedOn(DateTime(2026, 2, 10)), isTrue);
      expect(quit.isCompletedOn(DateTime(2026, 2, 11)), isFalse);
      expect(quit.completions[DateTime(2026, 2, 11).dayKey]!.count, 3);
      expect(quit.completions.length, 2);
      expect(read.kind, HabitKind.positive);
      expect(read.completions.length, 2);
      expect(read.isCompletedOn(DateTime(2026, 2, 11)), isFalse);
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
      expect(
        () => ImportService.parseBytes([0x00, 0x01, 0x02, 0x03]),
        throwsA(isA<ImportException>()),
      );
    });
  });
}
