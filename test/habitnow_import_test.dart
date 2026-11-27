import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/import_service.dart';

const _sample = r'D202611272036371{C1;1;00cn_quit;1|2;3;00cn_sports;3|3;7;00cn_nutrition;7|4;6;00cn_health;6|5;2;00cn_study;2|6;12;00cn_work;11|7;8;00cn_home;8|8;10;00cn_art;14|9;4;00cn_entertainment;4|10;118;00cn_other;9|11;15;00cn_task;15|12;11;00cn_meditation;10|13;5;00cn_social;5|14;13;00cn_finance;20|15;9;00cn_outdoor;18|16;130;Vvvh;8{H1;1;;Bbs;6;2a1;B6ar;;0;00;01;;;;;|2;2;;Bb;1;0a1;B6ar;;0;10;01;;;2;;|3;3;;Jj;4;0a1;B6ar;;0;60;01;;;;;|4;4;;Jdjdjdj;11;1c1;B6ar;;0;0;;|5;5;;Hh;1;0a1;B6ar;;0;01;01;;4 7 ;;;|6;6;;Nb;1;0a1;B6ar;;0;77;02;;;3600;;|7;7;;Jjj;12;0a1;B6ar;;0;35;01;ju;1 0;633;;|8;8;;Huy;1;2a1;B6ar;;0;01;01;;3 6 ;;;|9;9;;Jbh;11;1c3;B6a5;Juju;0;0;;{S{X1;B6ar;fa|2;B6ar;fa;;2|3;B6ar;fa|6;B6ar;fa;;3600|8;B6ar;fd{T{Y{R{O{F{P{G{bb3885e1d8178345';

const _history = r'D202611280048131{C1;1;00cn_quit;1{H7;7;;Water;1;0a1;B4ag;;0;10;01;glasses;;8;;|8;8;;Read;2;0a1;B4bv;;0;00;01;;;;;{S{X7;B4ag;fa;;8|7;B4ah;fd;12;8|7;B4ai;fc;3;8|7;B4aj;fc;;8|7;B501;fa;;8|8;B4bv;fa|8;B501;fd|8;B502;fc{T{Y{R{O{F{P{G{0123456789abcdef';

Habit _named(List<Habit> habits, String name) =>
    habits.firstWhere((h) => h.name == name);

void main() {
  test('a HabitNow backup is recognised and keeps every habit', () {
    final outcome = ImportService.parseBytes(utf8.encode(_sample), fileName: 'HabitNow_Backup.hn');

    expect(outcome.source, 'HabitNow');
    expect(outcome.habits, hasLength(9));
    expect(_named(outcome.habits, 'Bbs').kind, HabitKind.positive);
  });

  test('numeric and timer habits keep their goal and the amount of the day', () {
    final habits = ImportService.parseBytes(utf8.encode(_sample)).habits;

    final count = _named(habits, 'Bb');
    expect(count.kind, HabitKind.quantitative);
    expect(count.perDayTarget, 2);

    final timer = _named(habits, 'Nb');
    expect(timer.perDayTarget, 60);
    expect(timer.unitLabel, 'min');
    expect(timer.completions.values.single.count, 60);

    final unit = _named(habits, 'Jjj');
    expect(unit.perDayTarget, 633);
    expect(unit.unitLabel, 'ju');
  });

  test('history across years lands on the right days with the right amounts', () {
    final habits = ImportService.parseBytes(utf8.encode(_history)).habits;
    final water = _named(habits, 'Water');
    final read = _named(habits, 'Read');
    double amount(Habit habit, String key) => habit.completions[key]?.count ?? 0;

    expect(water.perDayTarget, 8);
    expect(water.unitLabel, 'glasses');
    expect(amount(water, '16-11-2024'), 8);
    expect(amount(water, '17-11-2024'), 12);
    expect(amount(water, '18-11-2024'), 3);
    expect(water.completions.containsKey('19-11-2024'), isFalse);
    expect(amount(water, '01-01-2025'), 8);

    expect(read.completions.keys, containsAll(['31-12-2024', '01-01-2025']));
    expect(read.completions.containsKey('02-01-2025'), isFalse);
  });
}
