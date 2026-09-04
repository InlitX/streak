import 'package:flutter/material.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/data/vacation.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/import_service.dart';
import 'package:streak/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class HabitsController extends ChangeNotifier {
  HabitsController() {
    _habits = LocalStore.readHabits();
  }

  final _uuid = const Uuid();
  final _notifications = NotificationService();

  late Map<String, Habit> _habits;
  List<Habit>? _active;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    _active = null;
    super.notifyListeners();
  }

  List<Habit> get habits => _active ??=
      _habits.values.where((h) => !h.isArchived).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<Habit> get archived {
    final list = _habits.values.where((h) => h.isArchived).toList()
      ..sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));
    return list;
  }

  bool get isEmpty => habits.isEmpty;

  Map<String, Habit> get asMap => {
        for (final entry in _habits.entries)
          if (!entry.value.isArchived) entry.key: entry.value,
      };

  Habit? byId(String id) => _habits[id];

  Future<void> rescheduleReminders() async {
    for (final habit in _habits.values) {
      if (habit.isArchived || habit.reminders.isEmpty) continue;
      await _notifications.scheduleFor(habit);
    }
  }

  Future<void> reload() async {
    if (LocalStore.isWriting) return;
    await LocalStore.reloadHabits();
    _habits = LocalStore.readHabits();
    notifyListeners();
  }

  Future<void> clearProgress() async {
    final photos = [
      for (final note in LocalStore.readNotes()) ...note.photos,
    ];
    await LocalStore.clearProgress();
    _habits = LocalStore.readHabits();
    notifyListeners();
    await CoverStorage.forgetAll(photos);
    await HomeWidgetService.sync(asMap);
  }

  Future<void> create({
    required String name,
    required String icon,
    required String category,
    required String description,
    required int color,
    required HabitInterval interval,
    required int targetFrequency,
    List<int> scheduleWeekdays = const [],
    int scheduleEvery = 2,
    required List<Reminder> reminders,
    String coverPath = '',
    HabitKind kind = HabitKind.positive,
    double dailyCost = 0,
    double perDayTarget = 1,
    String unitLabel = '',
    double incrementAmount = 1,
    QuantKind quantKind = QuantKind.generic,
    String bookCoverPath = '',
    bool focusOnly = false,
    bool tracking = false,
    int focusMinutes = 25,
    int focusBreakMinutes = 0,
    int startMinute = -1,
    int durationMinutes = 0,
    List<Substep> substeps = const [],
  }) async {
    final id = _uuid.v4();
    final habit = Habit(
      id: id,
      name: name,
      icon: icon,
      category: category,
      description: description,
      color: _color(color),
      order: habits.length,
      interval: interval,
      targetFrequency: targetFrequency,
      scheduleWeekdays: scheduleWeekdays,
      scheduleEvery: scheduleEvery,
      reminders: reminders,
      coverPath: coverPath,
      kind: kind,
      dailyCost: dailyCost,
      perDayTarget: perDayTarget,
      unitLabel: unitLabel,
      incrementAmount: incrementAmount,
      quantKind: quantKind,
      bookCoverPath: bookCoverPath,
      focusOnly: focusOnly,
      tracking: tracking,
      focusMinutes: focusMinutes,
      focusBreakMinutes: focusBreakMinutes,
      startMinute: startMinute,
      durationMinutes: durationMinutes,
      substeps: substeps,
    );
    _habits[id] = habit;
    await LocalStore.writeHabit(habit);
    notifyListeners();
    if (reminders.isNotEmpty) await _notifications.scheduleFor(habit);
    HomeWidgetService.syncSoon(() => asMap);
  }

  Future<void> update(Habit habit) async {
    _habits[habit.id] = habit;
    await LocalStore.writeHabit(habit);
    notifyListeners();
    await _notifications.scheduleFor(habit);
    HomeWidgetService.syncSoon(() => asMap);
  }

  Future<void> toggle(String id, DateTime date, {bool fromFocus = false}) async {
    final habit = _habits[id];
    if (habit == null) return;
    if (habit.blocksManualCheck(date, fromFocus: fromFocus)) return;
    await _apply(habit, CompletionOps.toggle(habit, date));
  }

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

  Future<void> addProgress(String id, DateTime date, double delta) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.addProgress(habit, date, delta));
  }

  Future<void> setProgress(String id, DateTime date, double value) async {
    final habit = _habits[id];
    if (habit == null) return;
    final current = habit.completions[date.dayKey]?.count ?? 0;
    await _apply(habit, CompletionOps.addProgress(habit, date, value - current));
  }

  Future<void> setStep(
    String id,
    DateTime date,
    String stepId,
    bool checked,
  ) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.setStep(habit, date, stepId, checked));
  }

  Future<void> setVacation(String id, bool on) async {
    final habit = _habits[id];
    if (habit == null) return;
    final periods = [...habit.vacations];
    if (on) {
      if (!periods.any((p) => p.isOngoing)) {
        periods.add(VacationPeriod(start: AppClock.now()));
      }
    } else {
      final yesterday =
          AppClock.now().atMidnight.subtract(const Duration(days: 1));
      final next = <VacationPeriod>[];
      for (final p in periods) {
        if (!p.isOngoing) {
          next.add(p);
        } else if (!yesterday.isBefore(p.start)) {
          next.add(p.copyWith(end: yesterday));
        }
      }
      periods
        ..clear()
        ..addAll(next);
    }
    await update(habit.copyWith(vacations: periods));
  }

  Future<List<String>> pauseAll() async {
    final paused = <String>[];
    for (final habit in habits) {
      if (habit.isArchived || habit.isOnVacation) continue;
      paused.add(habit.id);
      await setVacation(habit.id, true);
    }
    return paused;
  }

  Future<void> resumeAll(List<String> ids) async {
    for (final id in ids) {
      await setVacation(id, false);
    }
  }

  Future<void> setRestDays(String id, List<int> days) async {
    final habit = _habits[id];
    if (habit == null) return;
    await update(habit.copyWith(restDays: days));
  }

  Future<void> toggleVacationDay(String id, DateTime date) async {
    final habit = _habits[id];
    if (habit == null) return;
    final day = date.atMidnight;
    final previous = day.subtract(const Duration(days: 1));
    final next = day.add(const Duration(days: 1));

    if (!habit.isPausedOn(day)) {
      await update(
        habit.copyWith(
          vacations: [...habit.vacations, VacationPeriod(start: day, end: day)],
        ),
      );
      return;
    }

    final periods = <VacationPeriod>[];
    for (final period in habit.vacations) {
      if (!period.contains(day)) {
        periods.add(period);
        continue;
      }
      if (period.start.isBefore(day)) {
        periods.add(VacationPeriod(start: period.start, end: previous));
      }
      if (period.end == null) {
        periods.add(VacationPeriod(start: next));
      } else if (period.end!.isAfter(day)) {
        periods.add(VacationPeriod(start: next, end: period.end));
      }
    }
    await update(habit.copyWith(vacations: periods));
  }

  Future<void> _apply(
    Habit habit,
    Map<String, Completion> completions,
  ) async {
    final updated = habit.copyWith(completions: completions);
    _habits[habit.id] = updated;
    notifyListeners();
    HomeWidgetService.syncSoon(() => asMap);
    await LocalStore.guardWrites(() => LocalStore.writeHabit(updated));
  }

  Future<void> reorder(List<Habit> visible, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = [...visible];
    moved.insert(newIndex, moved.removeAt(oldIndex));

    final shown = {for (final habit in visible) habit.id};
    final ordered = [...habits];
    var next = 0;
    for (var i = 0; i < ordered.length; i++) {
      if (shown.contains(ordered[i].id)) ordered[i] = moved[next++];
    }

    final reordered = [
      for (var i = 0; i < ordered.length; i++)
        if (ordered[i].order != i) ordered[i].copyWith(order: i),
    ];
    for (final habit in reordered) {
      _habits[habit.id] = habit;
    }
    notifyListeners();

    await LocalStore.guardWrites(() async {
      for (final habit in reordered) {
        await LocalStore.writeHabit(habit);
      }
    });
    await HomeWidgetService.sync(asMap);
  }

  Future<void> archive(String id) async {
    final habit = _habits[id];
    if (habit == null) return;
    final archived = habit.copyWith(archivedAt: AppClock.now());
    _habits[id] = archived;
    await LocalStore.writeHabit(archived);
    notifyListeners();
    await _notifications.cancelFor(id);
    await HomeWidgetService.sync(asMap);
  }

  Future<void> restore(String id) async {
    final habit = _habits[id];
    if (habit == null) return;
    final restored =
        habit.copyWith(clearArchived: true, order: habits.length);
    _habits[id] = restored;
    await LocalStore.writeHabit(restored);
    notifyListeners();
    await HomeWidgetService.sync(asMap);
    if (restored.reminders.isNotEmpty) {
      await _notifications.scheduleFor(restored);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _notifications.cancelFor(id);
    } catch (e) {
      debugPrint('Could not cancel the reminders of $id: $e');
    }
    final habit = _habits[id];
    final images = [
      if (habit != null) ...[habit.coverPath, habit.bookCoverPath],
      for (final note in LocalStore.readNotes())
        if (note.habitId == id) ...note.photos,
    ];
    _habits.remove(id);
    await LocalStore.guardWrites(() async {
      await LocalStore.removeHabit(id);
      await LocalStore.removeNotesFor(id);
      await LocalStore.removeFocusFor(id);
    });
    notifyListeners();
    await CoverStorage.forgetAll(images);
    await HomeWidgetService.sync(asMap);
  }

  Future<bool> exportBackup({Rect? origin}) async {
    try {
      return await BackupService.export(
        _habits.values.toList(),
        origin: origin,
      );
    } catch (_) {
      return false;
    }
  }

  Future<ImportOutcome?> importFromApp() async {
    final outcome = await LocalStore.guardWrites(ImportService.pickAndParse);
    if (outcome == null) return null;
    await LocalStore.guardWrites(() async {
      var order = habits.length;
      for (final habit in outcome.habits) {
        final placed = habit.copyWith(order: order++);
        _habits[placed.id] = placed;
        await LocalStore.writeHabit(placed);
        if (placed.reminders.isNotEmpty) {
          await _notifications.scheduleFor(placed);
        }
      }
    });
    notifyListeners();
    await HomeWidgetService.sync(asMap);
    return outcome;
  }

  Future<String?> importBackup({bool replace = false}) async {
    try {
      final data = await LocalStore.guardWrites(BackupService.read);
      await LocalStore.guardWrites(() => _applyBackup(data, replace: replace));
      notifyListeners();
      await HomeWidgetService.sync(asMap);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _applyBackup(BackupData data, {required bool replace}) async {
    if (replace) {
      for (final id in _habits.keys.toList()) {
        await _notifications.cancelFor(id);
      }
      await LocalStore.wipeContent();
      _habits.clear();
    }
    for (final habit in data.habits) {
      _habits[habit.id] = habit;
      await LocalStore.writeHabit(habit);
    }
    for (final category in data.categories) {
      await LocalStore.writeCategory(category);
    }
    for (final note in data.notes) {
      await LocalStore.writeNote(note);
    }
    for (final session in data.focus) {
      await LocalStore.writeFocusSession(session);
    }
    for (final todo in data.todos) {
      await LocalStore.writeTodo(todo);
    }
    for (final habit in data.habits) {
      if (habit.reminders.isNotEmpty) await _notifications.scheduleFor(habit);
    }
  }

  static Color _color(int value) => Color(value);
}
