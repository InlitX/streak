import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';

class HomeWidgetService {
  const HomeWidgetService._();

  static const _providers = [
    'HabitWidgetProvider',
    'TodayWidgetProvider',
    'StatsWidgetProvider',
    'HeatmapWidgetProvider',
  ];

  static const _heatmapWeeks = 26;

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
        'kind': habit.kind.index,
        'perDayTarget': habit.perDayTarget,
        'incrementAmount': habit.incrementAmount,
        'counts': dates
            .map((d) => habit.completions[d.dayKey]?.count ?? 0)
            .toList(),
        'heatmap': _levelsOf(habit, today),
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
      'heatmap': _heatmapLevels(habits.values, today),
      'summary': {
        'doneToday': habits.values.where((h) => h.isCompletedOn(today)).length,
        'total': habits.length,
        'bestStreak': bestStreak,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Monday-aligned whole weeks so the widget columns line up.
  static List<DateTime> _heatmapDays(DateTime midnight) {
    final monday = midnight.subtract(Duration(days: midnight.weekday - 1));
    final start = monday.subtract(
      const Duration(days: 7 * (_heatmapWeeks - 1)),
    );
    return List.generate(
      _heatmapWeeks * 7,
      (i) => start.add(Duration(days: i)),
    );
  }

  // Level per day across all habits (1..4, 0 none, -1 future).
  static List<int> _heatmapLevels(Iterable<Habit> habits, DateTime today) {
    final midnight = today.atMidnight;
    // Negatives are clean by default and would paint everything at max.
    final tracked =
        habits.where((h) => h.kind != HabitKind.negative).toList();

    return _heatmapDays(midnight).map((day) {
      if (day.isAfter(midnight)) return -1;
      // Don't dim days before a habit existed.
      final active =
          tracked.where((h) => !day.isBefore(h.createdAt.atMidnight)).toList();
      if (active.isEmpty) return 0;
      final done = active.where((h) => h.isCompletedOn(day)).length;
      if (done == 0) return 0;
      return (done / active.length * 4).ceil().clamp(1, 4);
    }).toList();
  }

  // Same, for a single chosen habit.
  static List<int> _levelsOf(Habit habit, DateTime today) {
    final midnight = today.atMidnight;
    return _heatmapDays(midnight).map((day) {
      if (day.isAfter(midnight)) return -1;
      if (day.isBefore(habit.createdAt.atMidnight)) return 0;
      // For negatives a clean day is the good one, not a relapse.
      if (habit.kind == HabitKind.negative) {
        return habit.completions.containsKey(day.dayKey) ? 0 : 4;
      }
      final count = habit.completions[day.dayKey]?.count ?? 0;
      if (count <= 0) return 0;
      final target = habit.perDayTarget <= 0 ? 1 : habit.perDayTarget;
      return (count / target * 4).ceil().clamp(1, 4);
    }).toList();
  }
}
