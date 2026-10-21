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
import 'package:streak/services/backup_archive.dart';
import 'package:streak/services/backup_service.dart';
import 'package:streak/services/folder_sync.dart';
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
  List<Habit>? _every;
  int _countedOn = AppClock.today().epochDay;
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
    _every = null;
    super.notifyListeners();
  }

  List<Habit> get habits => _active ??=
      _habits.values.where((h) => !h.isArchived).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<Habit> get withArchived => _every ??= _habits.values.toList();

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
    try {
      await _notifications.cancelOrphans({
        for (final habit in _habits.values)
          if (!habit.isArchived) habit.id,
      });
    } catch (e) {
      debugPrint('Could not clear stale reminders: $e');
    }
    if (NotificationService.armedToday('habitRemindersArmedOn')) return;
    for (final habit in _habits.values) {
      if (habit.isArchived || habit.reminders.isEmpty) continue;
      await _notifications.scheduleFor(habit);
    }
  }

  Future<void> reload() async {
    if (LocalStore.isWriting) return;
    await LocalStore.reloadHabits();
    _habits = LocalStore.readHabits();
    _countedOn = AppClock.today().epochDay;
    notifyListeners();
  }

  void recount() {
    _habits = {for (final entry in _habits.entries) entry.key: entry.value.copyWith()};
    _countedOn = AppClock.today().epochDay;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (LocalStore.habitsChangedElsewhere) return reload();
    if (_countedOn != AppClock.today().epochDay) recount();
  }

  Future<void> clearProgress() async {
    await BackupService.safetyCopy();
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
    ScheduleUnit scheduleUnit = ScheduleUnit.days,
    DateTime? scheduleStart,
    bool fromLastDone = false,
    bool monthWeekday = false,
    required List<Reminder> reminders,
    String coverPath = '',
    int coverClarity = 100,
    HabitKind kind = HabitKind.positive,
    double dailyCost = 0,
    double perDayTarget = 1,
    String unitLabel = '',
    double incrementAmount = 1,
    QuantKind quantKind = QuantKind.generic,
    String bookCoverPath = '',
    bool focusOnly = false,
    bool tracking = false,
    bool healthSteps = false,
    bool anyAmount = false,
    bool anySteps = false,
    int stepsNeeded = 1,
    int difficulty = 0,
    int focusMinutes = 25,
    int focusBreakMinutes = 0,
    int startMinute = -1,
    int durationMinutes = 0,
    List<Substep> substeps = const [],
    List<int> restDays = const [],
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
      scheduleUnit: scheduleUnit,
      scheduleStart: scheduleStart,
      fromLastDone: fromLastDone,
      monthWeekday: monthWeekday,
      reminders: reminders,
      coverPath: coverPath,
      coverClarity: coverClarity,
      kind: kind,
      dailyCost: dailyCost,
      perDayTarget: perDayTarget,
      unitLabel: unitLabel,
      incrementAmount: incrementAmount,
      quantKind: quantKind,
      bookCoverPath: bookCoverPath,
      focusOnly: focusOnly,
      tracking: tracking,
      healthSteps: healthSteps,
      anyAmount: anyAmount,
      anySteps: anySteps,
      stepsNeeded: stepsNeeded,
      difficulty: difficulty,
      focusMinutes: focusMinutes,
      focusBreakMinutes: focusBreakMinutes,
      startMinute: startMinute,
      durationMinutes: durationMinutes,
      substeps: substeps,
      restDays: restDays,
    );
    _habits[id] = habit;
    await LocalStore.writeHabit(habit);
    notifyListeners();
    if (reminders.isNotEmpty) {
      try {
        await _notifications.scheduleFor(habit);
      } catch (e) {
        debugPrint('Scheduling ${habit.name} failed: $e');
      }
    }
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

  Future<void> addRelapse(String id, DateTime date) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.addRelapse(habit, date));
  }

  Future<void> dropRelapse(String id, DateTime date) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.dropRelapse(habit, date));
  }

  Future<void> retime(String id, String dayKey, int? from, int to) async {
    final habit = _habits[id];
    if (habit == null) return;
    await _apply(habit, CompletionOps.retime(habit, dayKey, from, to));
  }

  Future<void> setMissReason(String id, String dayKey, String? reason) async {
    final habit = _habits[id];
    if (habit == null) return;
    final reasons = {...habit.missReasons};
    if (reason == null || reason.trim().isEmpty) {
      reasons.remove(dayKey);
    } else {
      reasons[dayKey] = reason.trim();
    }
    await update(habit.copyWith(missReasons: reasons));
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

  Future<void> logSteps(String id, Map<DateTime, double> counts) async {
    final habit = _habits[id];
    if (habit == null || !habit.readsSteps) return;
    final completions = CompletionOps.raiseCounts(habit, counts);
    if (identical(completions, habit.completions)) return;
    await _apply(habit, completions);
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

  Future<void> setVacation(String id, bool on, {bool bulk = false}) async {
    final habit = _habits[id];
    if (habit == null) return;
    final periods = [...habit.vacations];
    if (on) {
      if (!periods.any((p) => p.isOngoing)) {
        periods.add(VacationPeriod(start: AppClock.now(), bulk: bulk));
      }
    } else {
      final yesterday = AppClock.today().addDays(-1);
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
      await setVacation(habit.id, true, bulk: true);
    }
    return paused;
  }

  Future<void> resumeAll(List<String> ids) async {
    for (final habit in [..._habits.values]) {
      if (habit.vacations.any((p) => p.isOngoing && p.bulk) ||
          ids.contains(habit.id)) {
        await setVacation(habit.id, false);
      }
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
    final previous = day.addDays(-1);
    final next = day.addDays(1);

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
    final today = AppClock.now();
    if (habit.reminders.isNotEmpty &&
        (habit.fromLastDone ||
            habit.silencesRemindersOn(today) !=
                updated.silencesRemindersOn(today))) {
      _refreshReminders(habit.id);
    }
  }

  Future<void> _reminderQueue = Future.value();

  void _refreshReminders(String id) {
    _reminderQueue = _reminderQueue.then((_) async {
      final habit = _habits[id];
      if (habit == null) return;
      try {
        await _notifications.scheduleFor(habit);
        await _notifications.dismissShown(habit);
      } catch (e) {
        debugPrint('Could not refresh the reminders of $id: $e');
      }
    });
  }

  void refreshDoneReminders() {
    final today = AppClock.now();
    for (final habit in _habits.values) {
      if (habit.isArchived || habit.reminders.isEmpty) continue;
      if (habit.silencesRemindersOn(today)) _refreshReminders(habit.id);
    }
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
      final into = <String, String>{};
      for (final habit in outcome.habits) {
        final same = _namedLike(habit);
        final placed = same == null
            ? habit.copyWith(order: order++)
            : same.copyWith(
                completions: FolderSync.mergeCompletions(
                  same.completions,
                  habit.completions,
                ),
                createdAt: habit.createdAt.isBefore(same.createdAt)
                    ? habit.createdAt
                    : same.createdAt,
              );
        into[habit.id] = placed.id;
        _habits[placed.id] = placed;
        await LocalStore.writeHabit(placed);
        if (placed.reminders.isNotEmpty) {
          await _notifications.scheduleFor(placed);
        }
      }
      final known = {
        for (final note in LocalStore.readNotes())
          (note.habitId, note.date, note.text),
      };
      for (final note in outcome.notes) {
        final moved = note.copyWith(habitId: into[note.habitId]);
        if (known.contains((moved.habitId, moved.date, moved.text))) continue;
        await LocalStore.writeNote(moved);
      }
    });
    notifyListeners();
    await HomeWidgetService.sync(asMap);
    return outcome;
  }

  Habit? _namedLike(Habit imported) {
    final name = imported.name.trim().toLowerCase();
    for (final habit in habits) {
      if (habit.id != imported.id &&
          habit.kind == imported.kind &&
          habit.name.trim().toLowerCase() == name) {
        return habit;
      }
    }
    return null;
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
      await BackupService.safetyCopy();
      for (final id in _habits.keys.toList()) {
        await _notifications.cancelFor(id);
      }
      await LocalStore.wipeContent();
      _habits.clear();
    }
    for (final theirs in data.habits) {
      final ours = _habits[theirs.id];
      final habit = ours == null
          ? theirs
          : ours.copyWith(
              completions:
                  FolderSync.mergeCompletions(ours.completions, theirs.completions),
              missReasons: {...theirs.missReasons, ...ours.missReasons},
            );
      _habits[habit.id] = habit;
      await LocalStore.writeHabit(habit);
    }
    Set<String> known<T>(List<T> items, String Function(T) id) =>
        replace ? const {} : items.map(id).toSet();
    final categories = known(LocalStore.readCategories(), (c) => c.id);
    final notes = known(LocalStore.readNotes(), (n) => n.id);
    final focus = known(LocalStore.readFocusSessions(), (f) => f.id);
    final todos = known(LocalStore.readTodos(), (t) => t.id);
    final tags = known(LocalStore.readTodoTags(), (t) => t.id);
    for (final category in data.categories) {
      if (categories.contains(category.id)) continue;
      replace
          ? await LocalStore.writeCategory(category)
          : await LocalStore.mergeCategory(category);
    }
    for (final note in data.notes) {
      if (!notes.contains(note.id)) await LocalStore.writeNote(note);
    }
    for (final session in data.focus) {
      if (!focus.contains(session.id)) await LocalStore.writeFocusSession(session);
    }
    for (final todo in data.todos) {
      if (!todos.contains(todo.id)) await LocalStore.writeTodo(todo);
    }
    for (final tag in data.todoTags) {
      if (!tags.contains(tag.id)) await LocalStore.writeTodoTag(tag);
    }
    if (replace) {
      for (final entry in data.settings.entries) {
        final value = entry.value;
        if (value == null || !backupSettingKeys.contains(entry.key)) continue;
        await LocalStore.writeSetting(entry.key, value);
      }
    }
    for (final habit in data.habits) {
      final current = _habits[habit.id];
      if (current != null && current.reminders.isNotEmpty) {
        await _notifications.scheduleFor(current);
      }
    }
  }

  static Color _color(int value) => Color(value);
}
