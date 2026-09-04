import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/icons/habit_icons.dart';
import 'package:streak/core/utils/app_dirs.dart';
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

  static const _weekDays = 7;

  static const _windowDays = 14;

  static const _allHabitsIcon = 'activity';

  static String? _lastLocale;
  static String? _locale;

  static Future<void> localize(
    AppLocalizations l10n,
    Map<String, Habit> habits,
  ) async {
    if (!hasHomeWidgets) return;
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
          'todos_open': l10n.widget_todos_open('{count}'),
          'todos_empty': l10n.widget_todos_empty,
          'best_streak': l10n.widget_best_streak('{streak}'),
          'label_week': l10n.week,
          'label_best': l10n.best,
          'cfg_title': l10n.widget_cfg_title,
          'cfg_color': l10n.widget_cfg_color,
          'cfg_image': l10n.widget_cfg_image,
          'cfg_choose_image': l10n.widget_cfg_choose_image,
          'cfg_change_image': l10n.widget_cfg_change_image,
          'cfg_custom_color': l10n.widget_cfg_custom_color,
          'cfg_follow_system': l10n.widget_cfg_follow_system,
          'cfg_dark_color': l10n.widget_cfg_dark_color,
          'cfg_light_color': l10n.widget_cfg_light_color,
          'cfg_opacity': l10n.widget_cfg_opacity('{value}'),
          'cfg_border': l10n.widget_cfg_border,
          'cfg_thickness': l10n.widget_cfg_thickness('{value}'),
          'cfg_todos_scope': l10n.widget_cfg_todos_scope,
          'cfg_todos_all': l10n.widget_cfg_todos_all,
          'cfg_todos_hint': l10n.widget_cfg_todos_hint,
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

  static Timer? _pendingSync;

  static void syncSoon(Map<String, Habit> Function() habits) {
    _pendingSync?.cancel();
    _pendingSync = Timer(const Duration(milliseconds: 700), () {
      _pendingSync = null;
      sync(habits());
    });
  }

  static Future<void> sync(
    Map<String, Habit> habits, {
    bool renderIcons = true,
  }) async {
    _pendingSync?.cancel();
    _pendingSync = null;
    if (!hasHomeWidgets) return;
    try {
      final icons = await WidgetIconService.resolve(
        [..._ordered(habits).map((h) => h.icon), _allHabitsIcon],
        render: renderIcons,
      );
      await HomeWidget.saveWidgetData<String>(
        'habits_data',
        _encode(habits, icons),
      );
      for (final provider in _providers) {
        await HomeWidget.updateWidget(androidName: provider);
      }
    } catch (e) {
      debugPrint('Widget sync failed: $e');
    }
  }

  static Future<void> syncWidgetStyle({
    required int bgColor,
    required int opacity,
    required bool border,
  }) async {
    if (!hasHomeWidgets) return;
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

  static List<String> _narrowWeekdays() {
    try {
      return DateFormat('', _locale ?? 'en').dateSymbols.NARROWWEEKDAYS;
    } catch (e) {
      debugPrint('Widget weekday labels fell back to English: $e');
      return const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    }
  }

  static List<Habit> _ordered(Map<String, Habit> habits) =>
      habits.values.where((habit) => !habit.isArchived).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  static String _encode(Map<String, Habit> habits, Map<String, String> icons) {
    final today = AppClock.now();
    final window = List.generate(
      _windowDays,
      (i) => today.subtract(Duration(days: _weekDays - 1 - i)),
    );
    final dates = window.take(_weekDays).toList();
    final listed = _ordered(habits);

    final widgetHabits = listed.map((habit) {
      return {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'iconPath': icons[habit.icon] ?? '',
        'iconTintable': HabitIcons.isIcon(habit.icon),
        'color': habit.color.toARGB32(),
        'cover': habit.coverPath,
        'completions': window.map(habit.isCompletedOn).toList(),
        'kind': habit.kind.index,
        'focusOnly': habit.needsFocusSession,
        'streak': habit.currentStreak,
        'perDayTarget': habit.effectiveTarget,
        'incrementAmount': habit.incrementAmount,
        'counts': window
            .map((d) => habit.completions[d.dayKey]?.count ?? 0.0)
            .toList(),
        'scheduled': window
            .map((d) => !habit.isPausedOn(d) && habit.isScheduledOn(d))
            .toList(),
        'heatmap': _levelsOf(habit, today),
      };
    }).toList();

    final narrow = _narrowWeekdays();
    final days = window.map((date) {
      return {
        'key': date.dayKey,
        'label': narrow[date.weekday % 7],
        'isToday': date.dayKey == today.dayKey,
      };
    }).toList();

    final counted = listed.where((h) => !h.tracking).toList();

    final bestStreak = counted
        .map((h) => h.currentStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);

    final due = counted
        .where((h) => !h.isPausedOn(today) && h.isScheduledOn(today))
        .toList();

    var weekDone = 0;
    for (final habit in counted) {
      for (final date in dates) {
        if (habit.isCompletedOn(date)) weekDone++;
      }
    }

    return json.encode({
      'habits': widgetHabits,
      'days': days,
      'todayKey': today.dayKey,
      'dayCutoff': AppClock.cutoffHour,
      'heatmap': _heatmapLevels(listed, today),
      'fallbackIconPath': icons[_allHabitsIcon] ?? '',
      'summary': {
        'doneToday': due.where((h) => h.isCompletedOn(today)).length,
        'total': due.length,
        'bestStreak': bestStreak,
        'weekDone': weekDone,
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
          tracked.where((h) => !day.isBefore(h.startedAt)).toList();
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
      if (day.isBefore(habit.startedAt)) return 0;
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
