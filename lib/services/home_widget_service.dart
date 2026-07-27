import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/l10n/app_localizations.dart';
import 'package:streak/services/widget_icon_service.dart';

class HomeWidgetService {
  const HomeWidgetService._();

  static const _providers = [
    'HabitWidgetProvider',
    'TodayWidgetProvider',
    'StatsWidgetProvider',
    'HeatmapWidgetProvider',
  ];

  static const _heatmapWeeks = 53;

  static const _allHabitsIcon = 'activity';

  static String? _lastLocale;
  static String? _locale;

  static Future<void> localize(
    AppLocalizations l10n,
    Map<String, Habit> habits,
  ) async {
    if (_lastLocale == l10n.localeName) return;
    _lastLocale = l10n.localeName;
    _locale = l10n.localeName;
    try {
      await HomeWidget.saveWidgetData<String>(
        'widget_strings',
        json.encode({
          'no_habits': l10n.widget_no_habits,
          'no_data': l10n.widget_no_data,
          'open_to_sync': l10n.widget_open_to_sync,
          'activity': l10n.widget_activity,
          'today_progress': l10n.widget_today_progress('{done}', '{total}'),
          'done_today': l10n.widget_done_today,
          'best_streak': l10n.widget_best_streak('{streak}'),
          'cfg_title': l10n.widget_cfg_title,
          'cfg_color': l10n.widget_cfg_color,
          'cfg_image': l10n.widget_cfg_image,
          'cfg_choose_image': l10n.widget_cfg_choose_image,
          'cfg_change_image': l10n.widget_cfg_change_image,
          'cfg_custom_color': l10n.widget_cfg_custom_color,
          'cfg_opacity': l10n.widget_cfg_opacity('{value}'),
          'cfg_border': l10n.widget_cfg_border,
          'cfg_thickness': l10n.widget_cfg_thickness('{value}'),
          'cfg_show_activity': l10n.widget_cfg_show_activity,
          'cfg_dot_color': l10n.widget_cfg_dot_color,
          'cfg_style': l10n.widget_cfg_style,
          'cfg_style_classic': l10n.widget_cfg_style_classic,
          'cfg_style_card': l10n.widget_cfg_style_card,
          'cfg_all_habits': l10n.widget_cfg_all_habits,
          'cfg_save': l10n.widget_cfg_save,
          'cfg_add': l10n.widget_cfg_add,
          'cfg_reset': l10n.widget_cfg_reset,
          'cfg_hue': l10n.widget_cfg_hue,
          'cfg_saturation': l10n.widget_cfg_saturation,
          'cfg_brightness': l10n.widget_cfg_brightness,
          'demo_read': l10n.widget_demo_read,
          'demo_run': l10n.widget_demo_run,
          'demo_water': l10n.widget_demo_water,
        }),
      );
    } catch (_) {}
    await sync(habits);
  }

  static Future<void> sync(
    Map<String, Habit> habits, {
    bool renderIcons = true,
  }) async {
    try {
      final icons = await WidgetIconService.resolve(
        [...habits.values.map((h) => h.icon), _allHabitsIcon],
        render: renderIcons,
      );
      await HomeWidget.saveWidgetData<String>(
        'habits_data',
        _encode(habits, icons),
      );
      for (final provider in _providers) {
        await HomeWidget.updateWidget(androidName: provider);
      }
    } catch (_) {}
  }

  static Future<void> syncWidgetStyle({
    required int bgColor,
    required int opacity,
    required bool border,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'widget_style',
        json.encode({
          'bgColor': bgColor,
          'opacity': opacity,
          'border': border,
        }),
      );
      for (final provider in _providers) {
        await HomeWidget.updateWidget(androidName: provider);
      }
    } catch (_) {}
  }

  static String _encode(Map<String, Habit> habits, Map<String, String> icons) {
    final today = DateTime.now();
    final dates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    final widgetHabits = habits.values.map((habit) {
      return {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'iconPath': icons[habit.icon] ?? '',
        'iconTintable': HabitIcons.isIcon(habit.icon),
        'color': habit.color.toARGB32(),
        'cover': habit.coverPath,
        'completions': dates.map(habit.isCompletedOn).toList(),
        'kind': habit.kind.index,
        'streak': habit.currentStreak,
        'perDayTarget': habit.effectiveTarget,
        'incrementAmount': habit.incrementAmount,
        'counts': dates
            .map((d) => habit.completions[d.dayKey]?.count ?? 0)
            .toList(),
        'heatmap': _levelsOf(habit, today),
      };
    }).toList();

    final narrow = DateFormat('', _locale ?? 'en').dateSymbols.NARROWWEEKDAYS;
    final days = dates.map((date) {
      return {
        'label': narrow[date.weekday % 7],
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
      'fallbackIconPath': icons[_allHabitsIcon] ?? '',
      'summary': {
        'doneToday': habits.values.where((h) => h.isCompletedOn(today)).length,
        'total': habits.length,
        'bestStreak': bestStreak,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

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

  static List<int> _heatmapLevels(Iterable<Habit> habits, DateTime today) {
    final midnight = today.atMidnight;
    final tracked =
        habits.where((h) => h.kind != HabitKind.negative).toList();

    return _heatmapDays(midnight).map((day) {
      if (day.isAfter(midnight)) return -1;
      final active =
          tracked.where((h) => !day.isBefore(h.createdAt.atMidnight)).toList();
      if (active.isEmpty) return 0;
      final done = active.where((h) => h.isCompletedOn(day)).length;
      if (done == 0) return 0;
      return (done / active.length * 4).ceil().clamp(1, 4);
    }).toList();
  }

  static List<int> _levelsOf(Habit habit, DateTime today) {
    final midnight = today.atMidnight;
    return _heatmapDays(midnight).map((day) {
      if (day.isAfter(midnight)) return -1;
      if (day.isBefore(habit.createdAt.atMidnight)) return 0;
      if (habit.kind == HabitKind.negative) {
        return habit.completions.containsKey(day.dayKey) ? 0 : 4;
      }
      final count = habit.completions[day.dayKey]?.count ?? 0;
      if (count <= 0) return 0;
      final target = habit.effectiveTarget <= 0 ? 1 : habit.effectiveTarget;
      return (count / target * 4).ceil().clamp(1, 4);
    }).toList();
  }
}
