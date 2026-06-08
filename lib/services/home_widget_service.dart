import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:streak/features/habits/data/habit.dart';

class HomeWidgetService {
  const HomeWidgetService._();

  static const _providers = [
    'HabitWidgetProvider',
    'TodayWidgetProvider',
    'StatsWidgetProvider',
  ];

  static Future<void> sync(Map<String, Habit> habits) async {
    try {
      await HomeWidget.saveWidgetData<String>('habits_data', _encode(habits));
      for (final provider in _providers) {
        await HomeWidget.updateWidget(androidName: provider);
      }
    } catch (_) {}
  }

  static String _encode(Map<String, Habit> habits) {
    final today = DateTime.now();
    final dates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    final widgetHabits = habits.values.map((habit) {
      return {
        'id': habit.id,
        'name': habit.name,
        'color': habit.color.toARGB32(),
        'cover': habit.coverPath,
        'completions': dates.map(habit.isCompletedOn).toList(),
      };
    }).toList();

    final days = dates.map((date) {
      return {
        'label': DateFormat.E().format(date)[0],
        'isToday': date.day == today.day &&
            date.month == today.month &&
            date.year == today.year,
      };
    }).toList();

    final bestStreak = habits.values
        .map((h) => h.currentStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return json.encode({
      'habits': widgetHabits,
      'days': days,
      'summary': {
        'doneToday': habits.values.where((h) => h.isCompletedOn(today)).length,
        'total': habits.length,
        'bestStreak': bestStreak,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
