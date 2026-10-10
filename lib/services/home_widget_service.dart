import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:streak/core/database/local_store.dart';
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

  static const appGroup = 'group.com.streak.app';

  static bool _grouped = false;

  static Future<void> prepare() async {
    if (!Platform.isIOS || _grouped) return;
    await HomeWidget.setAppGroupId(appGroup);
    _grouped = true;
  }

  static String? _lastLocale;
  static String? _locale;

  static Future<void> localize(
    AppLocalizations l10n,
    Map<String, Habit> Function() habits,
  ) async {
    if (!hasHomeWidgets) return;
    if (_lastLocale == l10n.localeName) return;
    _lastLocale = l10n.localeName;
    _locale = l10n.localeName;
    try {
      await prepare();
      await HomeWidget.saveWidgetData<String>(
        'widget_strings',
        json.encode({
          'no_habits': l10n.widget_no_habits,
          'no_data': l10n.widget_no_data,
          'open_to_sync': l10n.widget_open_to_sync,
          'activity': l10n.widget_activity,
          'today_progress': l10n.widget_today_progress('{done}', '{total}'),
          'done_today': l10n.widget_done_today,
          'today': l10n.today,
          'this_week': l10n.widget_this_week,
          'last_days': l10n.widget_last_days('{count}'),
          'week_done': l10n.widget_week_done('{done}', '{total}'),
          'today_done': l10n.widget_today_done('{done}', '{total}'),
          'streak_days': l10n.widget_streak_days,
          'todos_open': l10n.widget_todos_open('{count}'),
          'todos_empty': l10n.widget_todos_empty,
          'best_streak': l10n.widget_best_streak('{streak}'),
          'label_week': l10n.week,
          'label_best': l10n.best,
          'cfg_title': l10n.widget_cfg_title,
          'cfg_content': l10n.widget_cfg_content,
          'cfg_background': l10n.widget_cfg_background,
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
          'cfg_todos_all': l10n.widget_cfg_todos_all,
          'cfg_todos_hint': l10n.widget_cfg_todos_hint,
          'cfg_show_art': l10n.widget_cfg_show_art,
          'cfg_show_header': l10n.widget_cfg_show_header,
          'cfg_show_icons': l10n.widget_cfg_show_icons,
          'cfg_show_cards': l10n.widget_cfg_show_cards,
          'cfg_show_details': l10n.widget_cfg_show_details,
          'cfg_days': l10n.widget_cfg_days,
          'cfg_show_activity': l10n.widget_cfg_show_activity,
          'cfg_show_habits': l10n.widget_cfg_show_habits,
          'cfg_show_habits_hint': l10n.widget_cfg_show_habits_hint,
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
    await sync(habits());
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
      await prepare();
      final icons = await WidgetIconService.resolve(
        [..._ordered(habits).map((h) => h.icon), _allHabitsIcon],
        render: renderIcons,
      );
      await HomeWidget.saveWidgetData<String>(
        'habits_data',
        _encode(habits, icons),
      );
      for (final provider in _providers) {
        await HomeWidget.updateWidget(androidName: provider, iOSName: provider);
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
      await prepare();
      await HomeWidget.saveWidgetData<String>(
        'widget_style',
        json.encode({
          'bgColor': bgColor,
          'opacity': opacity,
          'border': border,
        }),
      );
      for (final provider in _providers) {
        await HomeWidget.updateWidget(androidName: provider, iOSName: provider);
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

  static String _dateLabel(String pattern, DateTime day) {
    String plain(String text) {
      final bare = text.replaceAll('.', '');
      return bare.isEmpty ? bare : bare[0].toUpperCase() + bare.substring(1);
    }

    try {
      return plain(DateFormat(pattern, _locale ?? 'en').format(day));
    } catch (e) {
      return '';
    }
  }

  static List<Habit> _ordered(Map<String, Habit> habits) =>
      habits.values.where((habit) => !habit.isArchived).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  static String _encode(Map<String, Habit> habits, Map<String, String> icons) {
    final today = AppClock.now();
    final window = List.generate(
      _windowDays,
      (i) => today.addDays(i - (_weekDays - 1)),
    );
    final weekStart = LocalStore.setting('weekStart', 1);
    final weekOffset = _weekDays - 1 - (today.weekday - weekStart + 7) % 7;
    final dates = window.take(_weekDays).toList();
    final earlier = [today.addDays(-_weekDays - 1), today.addDays(-_weekDays)];
    final listed = _ordered(habits);

    final widgetHabits = listed.map((habit) {
      return {
        'id': habit.id,
        'name': habit.name,
        'description': habit.description,
        'iconPath': icons[habit.icon] ?? '',
        if (Platform.isIOS) 'iconData': _iconData(icons[habit.icon]),
        'iconTintable': HabitIcons.isIcon(habit.icon),
        'color': habit.color.toARGB32(),
        'cover': habit.coverPath,
        'completions': window.map(habit.isCompletedOn).toList(),
        'kind': habit.kind.index,
        'focusOnly': habit.needsFocusSession,
        'streak': habit.currentStreak,
        'best': habit.longestStreak,
        'tracking': habit.tracking,
        'weight': habit.difficultyWeight,
        'perDayTarget': habit.effectiveTarget,
        'clock': habit.isTimeAmount,
        'anyAmount': habit.acceptsAnyAmount,
        'incrementAmount': habit.incrementAmount,
        'counts': window
            .map((d) => habit.completions[d.dayKey]?.count ?? 0.0)
            .toList(),
        'scheduled': window
            .map((d) => !habit.isPausedOn(d) && habit.isScheduledOn(d))
            .toList(),
        'heatmap': _levelsOf(habit, today),
        'earlier': {
          'completions': earlier.map(habit.isCompletedOn).toList(),
          'counts': earlier
              .map((d) => habit.completions[d.dayKey]?.count ?? 0.0)
              .toList(),
          'scheduled': earlier
              .map((d) => !habit.isPausedOn(d) && habit.isScheduledOn(d))
              .toList(),
        },
      };
    }).toList();

    final narrow = _narrowWeekdays();
    Map<String, Object> dayOf(DateTime date) => {
          'key': date.dayKey,
          'label': narrow[date.weekday % 7],
          'short': _dateLabel('ccc', date),
          'isToday': date.dayKey == today.dayKey,
        };
    final days = window.map(dayOf).toList();

    final counted = listed.where((h) => !h.tracking).toList();

    final bestStreak = counted
        .map((h) => h.currentStreak)
        .fold<int>(0, (a, b) => a > b ? a : b);

    final due = counted
        .where((h) => !h.isPausedOn(today) && h.isScheduledOn(today))
        .toList();

    final finished = due
        .where((h) => h.isCompletedOn(today) || h.isCoveredOn(today))
        .toList();
    final weight = due.fold<int>(0, (sum, h) => sum + h.difficultyWeight);

    var weekDone = 0;
    for (final habit in counted) {
      for (final date in dates) {
        if (habit.isCompletedOn(date)) weekDone++;
      }
    }

    return json.encode({
      'habits': widgetHabits,
      'days': days,
      'earlierDays': earlier.map(dayOf).toList(),
      'weekOffset': weekOffset,
      'todayKey': today.dayKey,
      'dateLabel': _dateLabel('MMMd', today),
      'weekdayLabel': _dateLabel('EEEE', today),
      'dayCutoff': AppClock.cutoffHour,
      'pastFirst': LocalStore.setting('pastFirst', false),
      'heatmap': _heatmapLevels(listed, today),
      'fallbackIconPath': icons[_allHabitsIcon] ?? '',
      if (Platform.isIOS) 'fallbackIconData': _iconData(icons[_allHabitsIcon]),
      'summary': {
        'doneToday': finished.length,
        'ratio': weight == 0
            ? 0.0
            : finished.fold<int>(0, (sum, h) => sum + h.difficultyWeight) /
                weight,
        'total': due.length,
        'bestStreak': bestStreak,
        'weekDone': weekDone,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static String _iconData(String? path) {
    if (path == null) return '';
    try {
      return base64Encode(File(path).readAsBytesSync());
    } catch (_) {
      return '';
    }
  }

  static List<DateTime> _heatmapDays(DateTime midnight) {
    final start = midnight
        .startOfWeek(LocalStore.setting('weekStart', 1))
        .addDays(-7 * (_heatmapWeeks - 1));
    return List.generate(_heatmapWeeks * 7, start.addDays);
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
