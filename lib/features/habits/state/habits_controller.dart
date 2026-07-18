import 'package:flutter/material.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class HabitsController extends ChangeNotifier {
  HabitsController() {
    _habits = LocalStore.readHabits();
  }

  final _uuid = const Uuid();
  final _notifications = NotificationService();

  late Map<String, Habit> _habits;

  List<Habit> get habits {
    final list = _habits.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  bool get isEmpty => _habits.isEmpty;
  Map<String, Habit> get asMap => _habits;

  Habit? byId(String id) => _habits[id];

  // Reopen from disk on resume so widget-toggled completions show up.
  Future<void> reload() async {
    await LocalStore.reloadHabits();
    _habits = LocalStore.readHabits();
    notifyListeners();
  }

  Future<void> create({
    required String name,
    required String icon,
    required String category,
    required String description,
    required int color,
    required HabitInterval interval,
    required int targetFrequency,
    required List<Reminder> reminders,
    String coverPath = '',
    HabitKind kind = HabitKind.positive,
    int perDayTarget = 1,
    String unitLabel = '',
    int incrementAmount = 1,
    QuantKind quantKind = QuantKind.generic,
    String bookCoverPath = '',
  }) async {
    final id = _uuid.v4();
    final habit = Habit(
      id: id,
      name: name,
      icon: icon,
      category: category,
      description: description,
      color: _color(color),
      order: _habits.length,
      interval: interval,
      targetFrequency: targetFrequency,
      reminders: reminders,
      coverPath: coverPath,
      kind: kind,
      perDayTarget: perDayTarget,
      unitLabel: unitLabel,
      incrementAmount: incrementAmount,
      quantKind: quantKind,
      bookCoverPath: bookCoverPath,
    );
    _habits[id] = habit;
    await LocalStore.writeHabit(habit);
    notifyListeners();
    await HomeWidgetService.sync(_habits);
    if (reminders.isNotEmpty) await _notifications.scheduleFor(habit);
  }

  Future<void> update(Habit habit) async {
    _habits[habit.id] = habit;
    await LocalStore.writeHabit(habit);
    notifyListeners();
    await HomeWidgetService.sync(_habits);
    await _notifications.scheduleFor(habit);
  }

  Future<void> toggle(String id, DateTime date) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.toggle(habit, date));
  }

  // Breaks the clean streak. Home card confirms first; calendar toggles directly.
  Future<void> logRelapse(String id, DateTime date) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.logRelapse(habit, date));
  }

  Future<void> clearRelapse(String id, DateTime date) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.clearRelapse(habit, date));
  }

  Future<void> addProgress(String id, DateTime date, int delta) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.addProgress(habit, date, delta));
  }

  Future<void> setProgress(String id, DateTime date, int value) async {
    final habit = _habits[id];
    if (habit == null) return;
    final current = habit.completions[date.dayKey]?.count ?? 0;
    await _apply(habit, CompletionOps.addProgress(habit, date, value - current));
  }

  Future<void> _apply(
    Habit habit,
    Map<String, Completion> completions,
  ) async {
    final updated = habit.copyWith(completions: completions);
    _habits[habit.id] = updated;
    await LocalStore.writeHabit(updated);
    notifyListeners();
    await HomeWidgetService.sync(_habits);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final ordered = habits;
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    for (var i = 0; i < ordered.length; i++) {
      final updated = ordered[i].copyWith(order: i);
      _habits[updated.id] = updated;
      await LocalStore.writeHabit(updated);
    }
    notifyListeners();
    await HomeWidgetService.sync(_habits);
  }

  Future<void> remove(String id) async {
    await _notifications.cancelFor(id);
    _habits.remove(id);
    await LocalStore.removeHabit(id);
    notifyListeners();
    await HomeWidgetService.sync(_habits);
  }

  Future<bool> exportBackup() async {
    try {
      return await BackupService.export(_habits.values.toList());
    } catch (_) {
      return false;
    }
  }

  // replace = wipe first; otherwise merge by id.
  Future<String?> importBackup({bool replace = false}) async {
    try {
      final imported = await BackupService.import();
      if (replace) {
        for (final id in _habits.keys.toList()) {
          await _notifications.cancelFor(id);
          await LocalStore.removeHabit(id);
        }
        _habits.clear();
      }
      for (final habit in imported) {
        _habits[habit.id] = habit;
        await LocalStore.writeHabit(habit);
        if (habit.reminders.isNotEmpty) {
          await _notifications.scheduleFor(habit);
        }
      }
      notifyListeners();
      await HomeWidgetService.sync(_habits);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  static Color _color(int value) => Color(value);
}
