import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/focus/data/focus_session.dart';
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
    final raw = LocalStore.setting('focusActive', const <String, dynamic>{});
    if (raw.isEmpty) return;
    final map = Map<String, dynamic>.from(raw as Map);
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
    if (_open && _since != null) _startTicker();
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

  int get elapsedSeconds {
    final live =
        _since == null ? 0 : DateTime.now().difference(_since!).inSeconds;
    return _accumulated + live;
  }

  bool get isFlow => _targetMinutes <= 0;

  int get remainingSeconds =>
      isFlow ? 0 : (targetSeconds - elapsedSeconds).clamp(0, targetSeconds);

  int get displaySeconds => isFlow ? elapsedSeconds : remainingSeconds;

  double get progress => isFlow
      ? (elapsedSeconds % 60) / 60
      : (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);

  bool get reachedTarget => !isFlow && elapsedSeconds >= targetSeconds;

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
    notifyListeners();
  }

  void pause() {
    if (_since == null) return;
    _accumulated += DateTime.now().difference(_since!).inSeconds;
    _since = null;
    _stopTicker();
    _persist();
    notifyListeners();
  }

  void resume() {
    if (_since != null) return;
    _since = DateTime.now();
    _startTicker();
    _persist();
    notifyListeners();
  }

  void reset() {
    _accumulated = 0;
    _since = isRunning ? DateTime.now() : null;
    _celebrated = false;
    _persist();
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

  Future<FocusSession?> stop({required bool completed}) async {
    final seconds = _isBreak ? 0 : elapsedSeconds;
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
      startedAt: DateTime.now().subtract(Duration(seconds: seconds)),
    );
    _sessions.add(session);
    await LocalStore.writeFocusSession(session);
    notifyListeners();
    return session;
  }

  Future<void> _advancePhase() async {
    if (!_isBreak) {
      final seconds = elapsedSeconds;
      if (seconds >= 30) {
        final session = FocusSession(
          id: const Uuid().v4(),
          habitId: _habitId,
          targetMinutes: _focusMinutes,
          seconds: seconds,
          completed: true,
          startedAt: DateTime.now().subtract(Duration(seconds: seconds)),
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
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_celebrated && reachedTarget) {
        _celebrated = true;
        completedTick.value++;
        if (isPomodoro) _advancePhase();
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
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
