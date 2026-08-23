import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/services/home_widget_service.dart';

import 'support/app_harness.dart';

const _channel = MethodChannel('home_widget');

Future<Map<String, dynamic>> _payloadOf(List<Habit> habits) async {
  String? saved;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    if (call.method == 'saveWidgetData') {
      final args = call.arguments as Map;
      if (args['id'] == 'habits_data') saved = args['data'] as String?;
    }
    return true;
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  await HomeWidgetService.sync(
    {for (final habit in habits) habit.id: habit},
    renderIcons: false,
  );
  expect(saved, isNotNull, reason: 'the widget payload was never saved');
  return json.decode(saved!) as Map<String, dynamic>;
}

void main() {
  useEmptyStore();

  test('the payload carries two weeks of dated days', () async {
    final payload = await _payloadOf([testHabit(id: 'a', name: 'Read')]);
    final days = payload['days'] as List;
    final today = AppClock.now();

    expect(days.length, 14);
    expect(payload['todayKey'], today.dayKey);
    expect(days[6]['key'], today.dayKey);
    expect(days[6]['isToday'], isTrue);
    expect(days[0]['key'], today.subtract(const Duration(days: 6)).dayKey);
    expect(days[13]['key'], today.add(const Duration(days: 7)).dayKey);
    for (final day in days) {
      expect(day['key'], isNotNull);
      expect(day['label'], isNotNull);
      expect(parseDayKey(day['key'] as String), isNotNull);
    }
  });

  test('every habit answers for the whole window', () async {
    final payload = await _payloadOf([
      testHabit(id: 'a', name: 'Read'),
      testHabit(id: 'b', name: 'Water'),
    ]);

    for (final habit in payload['habits'] as List) {
      expect((habit['completions'] as List).length, 14, reason: habit['name']);
      expect((habit['counts'] as List).length, 14, reason: habit['name']);
      expect((habit['scheduled'] as List).length, 14, reason: habit['name']);
    }
  });

  test('a habit that is not due today says so for today and tomorrow',
      () async {
    final today = AppClock.now();
    final payload = await _payloadOf([
      testHabit(
        id: 'a',
        name: 'Only tomorrow',
        interval: HabitInterval.weekdays,
        scheduleWeekdays: [today.add(const Duration(days: 1)).weekday],
      ),
    ]);
    final scheduled = (payload['habits'] as List).first['scheduled'] as List;

    expect(scheduled[6], isFalse);
    expect(scheduled[7], isTrue);
    expect((payload['summary'] as Map)['total'], 0);
  });

  test('archived habits stay out of the widget', () async {
    final payload = await _payloadOf([
      testHabit(id: 'a', name: 'Read'),
      testHabit(id: 'b', name: 'Gone').copyWith(archivedAt: AppClock.now()),
    ]);

    expect(
      [for (final habit in payload['habits'] as List) habit['name']],
      ['Read'],
    );
  });

  test('the habits keep the order of the app', () async {
    final payload = await _payloadOf([
      testHabit(id: 'a', name: 'Third', order: 2),
      testHabit(id: 'b', name: 'First', order: 0),
      testHabit(id: 'c', name: 'Second', order: 1),
    ]);

    expect(
      [for (final habit in payload['habits'] as List) habit['name']],
      ['First', 'Second', 'Third'],
    );
  });

  test('the payload tells the widget where the day is cut', () async {
    addTearDown(() => AppClock.cutoffHour = 0);

    AppClock.cutoffHour = 0;
    var payload = await _payloadOf([testHabit(id: 'a', name: 'Read')]);
    expect(payload['dayCutoff'], 0);
    expect(payload['todayKey'], AppClock.now().dayKey);

    AppClock.cutoffHour = 3;
    payload = await _payloadOf([testHabit(id: 'a', name: 'Read')]);
    expect(payload['dayCutoff'], 3);
    expect(payload['todayKey'], AppClock.now().dayKey);
  });
}
