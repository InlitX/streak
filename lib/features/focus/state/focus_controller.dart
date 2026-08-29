import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/services/focus_service.dart';
import 'package:streak/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class FocusTask {
  FocusTask({required this.id, this.title = '', this.done = false});

  final String id;
  String title;
  bool done;
}

class FocusController extends ChangeNotifier {
  FocusController() {
    _sessions = LocalStore.readFocusSessions();
    _restore();
  }

  final ValueNotifier<int> completedTick = ValueNotifier(0);
  bool _celebrated = false;

  void _restore() {
    final map = LocalStore.settingMap('focusActive');
    if (map.isEmpty) return;
    _habitId = (map['habitId'] ?? '') as String;
    _targetMinutes = ((map['target'] ?? 25) as num).toInt();
    _focusMinutes = ((map['focus'] ?? _targetMinutes) as num).toInt();
    _breakMinutes = ((map['break'] ?? 0) as num).toInt();
    _isBreak = (map['isBreak'] ?? false) as bool;
    _round = ((map['round'] ?? 1) as num).toInt();
    _accumulated = ((map['acc'] ?? 0) as num).toInt();
    final since = (map['since'] ?? '') as String;
    _since = since.isEmpty ? null : DateTime.tryParse(since);
    _open = (map['open'] ?? false) as bool;
    if (!_open) return;
    if (_since == null && _accumulated <= 0) {
      _open = false;
      return;
    }
    if (isRunning) _startTicker();
    _sync();
  }

  void _persist() {
    LocalStore.writeSetting('focusActive', {
      'habitId': _habitId,
      'target': _targetMinutes,
      'focus': _focusMinutes,
      'break': _breakMinutes,
      'isBreak': _isBreak,
      'round': _round,
      'acc': _accumulated,
      'since': _since?.toIso8601String() ?? '',
      'open': _open,
    });
  }

  late List<FocusSession> _sessions;
  final List<FocusTask> _tasks = [];

  String _habitId = '';
  int _targetMinutes = 25;
  int _focusMinutes = 25;
  int _breakMinutes = 0;
  bool _isBreak = false;
  int _round = 1;
  bool _open = false;
  int _accumulated = 0;
  DateTime? _since;
  Timer? _ticker;

  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  void reload() {
    _sessions = LocalStore.readFocusSessions();
    notifyListeners();
  }

  Future<void> removeSessions(Set<String> ids) async {
    if (ids.isEmpty) return;
    await LocalStore.removeFocusSessions(ids);
    _sessions = _sessions.where((s) => !ids.contains(s.id)).toList();
    notifyListeners();
  }

  Future<FocusSession> addSession({
    required String habitId,
    required DateTime startedAt,
    required int minutes,
  }) async {
    final session = FocusSession(
      id: const Uuid().v4(),
      habitId: habitId,
      targetMinutes: minutes,
      seconds: minutes * 60,
      completed: true,
      startedAt: startedAt,
    );
    _sessions.add(session);
    await LocalStore.writeFocusSession(session);
    notifyListeners();
    return session;
  }

  List<FocusTask> get tasks => List.unmodifiable(_tasks);
  int get pendingTasks => _tasks.where((t) => !t.done).length;

  String get habitId => _habitId;
  bool get isBreak => _isBreak;
  int get round => _round;
  bool get isPomodoro => _breakMinutes > 0;
  int get targetMinutes => _targetMinutes;
  int get targetSeconds => _targetMinutes * 60;

  bool get isActive => _open;
  bool get isRunning => _since != null;

  int elapsedAt(DateTime at) {
    final live = _since == null ? 0 : at.difference(_since!).inSeconds;
    final total = _accumulated + live;
    return isFlow ? total : total.clamp(0, targetSeconds);
  }

  int get elapsedSeconds => elapsedAt(DateTime.now());

  bool get isFlow => _targetMinutes <= 0;

  int get remainingSeconds =>
      isFlow ? 0 : (targetSeconds - elapsedSeconds).clamp(0, targetSeconds);

  int get displaySeconds => isFlow ? elapsedSeconds : remainingSeconds;

  double get progress => isFlow
      ? (elapsedSeconds % 60) / 60
      : (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);

  bool get reachedTarget => !isFlow && elapsedSeconds >= targetSeconds;

  DateTime get _phaseEnd => _since == null
      ? DateTime.now()
      : _since!.add(Duration(seconds: targetSeconds - _accumulated));

  void start({
    required String habitId,
    required int targetMinutes,
    int breakMinutes = 0,
  }) {
    _habitId = habitId;
    _targetMinutes = targetMinutes;
    _focusMinutes = targetMinutes;
    _breakMinutes = targetMinutes <= 0 ? 0 : breakMinutes;
    _isBreak = false;
    _round = 1;
    _open = true;
    _accumulated = 0;
    _tasks.clear();
    _since = DateTime.now();
    _celebrated = false;
    _startTicker();
    _persist();
    _sync();
    notifyListeners();
  }

  void pause({DateTime? at}) {
    if (_since == null) return;
    _accumulated = elapsedAt(at ?? DateTime.now());
    _since = null;
    _stopTicker();
    _persist();
    _sync();
    notifyListeners();
  }

  void resume({DateTime? at}) {
    if (_since != null) return;
    _since = at ?? DateTime.now();
    _startTicker();
    _persist();
    _sync();
    notifyListeners();
  }

  void reset() {
    _accumulated = 0;
    _since = isRunning ? DateTime.now() : null;
    _celebrated = false;
    if (isRunning) _startTicker();
    _persist();
    _sync();
    notifyListeners();
  }

  void addTask() {
    _tasks.add(FocusTask(id: DateTime.now().microsecondsSinceEpoch.toString()));
    notifyListeners();
  }

  void setTaskTitle(String id, String title) {
    for (final task in _tasks) {
      if (task.id == id) task.title = title;
    }
  }

  void toggleTask(String id) {
    for (final task in _tasks) {
      if (task.id == id) task.done = !task.done;
    }
    notifyListeners();
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<FocusSession?> apply(FocusAction action) async {
    if (!_open) return null;
    switch (action.kind) {
      case FocusAction.pause:
        pause(at: action.at);
      case FocusAction.resume:
        resume(at: action.at);
      case FocusAction.stop:
        return stop(completed: reachedTarget || isFlow, at: action.at);
    }
    return null;
  }

  Future<FocusSession?> stop({required bool completed, DateTime? at}) async {
    final endedAt = at ?? DateTime.now();
    final seconds = _isBreak ? 0 : elapsedAt(endedAt);
    final habitId = _habitId;
    final target = _focusMinutes;
    _stopTicker();
    _accumulated = 0;
    _since = null;
    _habitId = '';
    _tasks.clear();
    _celebrated = false;
    _isBreak = false;
    _breakMinutes = 0;
    _round = 1;
    _open = false;
    _persist();
    _sync();

    if (seconds < 30) {
      notifyListeners();
      return null;
    }

    final session = FocusSession(
      id: const Uuid().v4(),
      habitId: habitId,
      targetMinutes: target,
      seconds: seconds,
      completed: completed,
      startedAt: endedAt.subtract(Duration(seconds: seconds)),
    );
    _sessions.add(session);
    await LocalStore.writeFocusSession(session);
    notifyListeners();
    return session;
  }

  Future<void> _advancePhase() async {
    final endedAt = _phaseEnd;
    if (!_isBreak) {
      final seconds = elapsedAt(endedAt);
      if (seconds >= 30) {
        final session = FocusSession(
          id: const Uuid().v4(),
          habitId: _habitId,
          targetMinutes: _focusMinutes,
          seconds: seconds,
          completed: true,
          startedAt: endedAt.subtract(Duration(seconds: seconds)),
        );
        _sessions.add(session);
        await LocalStore.writeFocusSession(session);
      }
    } else {
      _round++;
    }
    _isBreak = !_isBreak;
    _targetMinutes = _isBreak ? _breakMinutes : _focusMinutes;
    _accumulated = 0;
    _since = DateTime.now();
    _celebrated = false;
    _persist();
    _sync();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_celebrated && reachedTarget) {
        _celebrated = true;
        completedTick.value++;
        if (isPomodoro) {
          _advancePhase();
        } else {
          _stopTicker();
          _sync();
        }
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int get _anchorMs {
    final since = _since;
    if (since == null) return 0;
    final began = since.millisecondsSinceEpoch - _accumulated * 1000;
    return isFlow ? began : began + targetSeconds * 1000 + 999;
  }

  Future<void> _sync() async {
    try {
      if (!_open) {
        await FocusService.hide();
        return;
      }
      final strings = await NotificationService().localizations();
      final habit = _habitId.isEmpty ? null : LocalStore.readHabits()[_habitId];
      final done = reachedTarget && !isPomodoro;
      final label = done
          ? strings.focus_target_reached
          : _isBreak
              ? strings.focus_break
              : !isRunning
                  ? strings.focus_paused
                  : isFlow
                      ? strings.focus_flowtime
                      : strings.focus_notif_running;
      final phase = done
          ? 'done'
          : _isBreak
              ? 'break'
              : isRunning
                  ? 'running'
                  : 'paused';
      await FocusService.show(
        habitId: _habitId,
        title: habit?.name ?? strings.focus,
        state: isPomodoro
            ? '$label  ·  ${strings.focus_round(_round)}'
            : label,
        phase: phase,
        running: isRunning && !done,
        done: done,
        countDown: !isFlow,
        seconds: displaySeconds,
        anchor: _anchorMs,
        channelName: strings.focus_notif_channel,
        pauseLabel: strings.focus_pause,
        resumeLabel: strings.focus_resume,
        stopLabel: strings.focus_end,
      );
    } catch (e) {
      debugPrint('Focus notification sync failed: $e');
    }
  }

  int get totalSeconds =>
      _sessions.fold(0, (sum, session) => sum + session.seconds);

  int get sessionCount => _sessions.length;

  int secondsForHabit(String habitId) => _sessions
      .where((s) => s.habitId == habitId)
      .fold(0, (sum, session) => sum + session.seconds);

  int secondsForDay(DateTime day) => _sessions
      .where((s) => s.startedAt.dayKey == day.dayKey)
      .fold(0, (sum, session) => sum + session.seconds);

  int secondsForHabitSince(String habitId, DateTime from) => _sessions
      .where((s) =>
          s.habitId == habitId && !s.startedAt.atMidnight.isBefore(from))
      .fold(0, (sum, session) => sum + session.seconds);

  List<FocusSession> sessionsForHabitOnDay(String habitId, DateTime day) =>
      _sessions
          .where((s) => s.habitId == habitId && s.startedAt.dayKey == day.dayKey)
          .toList();

  int secondsForHabitOnDay(String habitId, DateTime day) =>
      sessionsForHabitOnDay(habitId, day)
          .fold(0, (sum, session) => sum + session.seconds);

  Future<void> removeForHabit(String habitId) async {
    _sessions.removeWhere((s) => s.habitId == habitId);
    await LocalStore.removeFocusFor(habitId);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
