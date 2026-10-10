import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/state/focus_audio.dart';
import 'package:streak/l10n/app_localizations.dart';
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
    _label = map['label'] is String ? map['label'] as String : '';
    _targetMinutes = ((map['target'] ?? 25) as num).toInt();
    _focusMinutes = ((map['focus'] ?? _targetMinutes) as num).toInt();
    _breakMinutes = ((map['break'] ?? 0) as num).toInt();
    _isBreak = (map['isBreak'] ?? false) as bool;
    _round = ((map['round'] ?? 1) as num).toInt();
    _accumulated = ((map['acc'] ?? 0) as num).toInt();
    final since = (map['since'] ?? '') as String;
    _since = since.isEmpty ? null : DateTime.tryParse(since)?.toLocal();
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
      'label': _label,
      'target': _targetMinutes,
      'focus': _focusMinutes,
      'break': _breakMinutes,
      'isBreak': _isBreak,
      'round': _round,
      'acc': _accumulated,
      'since': _since?.toUtc().toIso8601String() ?? '',
      'open': _open,
    });
  }

  late List<FocusSession> _sessions;
  final List<FocusTask> _tasks = [];

  String _habitId = '';
  String _label = '';
  int _targetMinutes = 25;
  int _focusMinutes = 25;
  int _breakMinutes = 0;
  bool _isBreak = false;
  bool _soundOnBreak = false;
  bool _soundOnPause = false;
  void Function(FocusSession session)? onRoundSaved;
  int _round = 1;
  bool _open = false;
  bool _awaiting = false;
  int _switchIn = 0;
  int _accumulated = 0;
  DateTime? _since;
  Timer? _ticker;
  List<FocusSession>? _view;
  Map<String, int>? _perDay;
  int _revision = 0;

  int get revision => _revision;

  List<FocusSession> get sessions => _view ??= List.unmodifiable(_sessions);

  @override
  void notifyListeners() {
    _revision++;
    _view = null;
    _perDay = null;
    super.notifyListeners();
  }

  void _tick() => super.notifyListeners();

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

  Future<void> markCounted(String id) async {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final counted = _sessions[index].asCounted;
    _sessions[index] = counted;
    _view = null;
    _perDay = null;
    await LocalStore.writeFocusSession(counted);
  }

  Future<FocusSession> addSession({
    required String habitId,
    required DateTime startedAt,
    required int minutes,
    String label = '',
  }) async {
    final session = FocusSession(
      id: const Uuid().v4(),
      habitId: habitId,
      targetMinutes: minutes,
      seconds: minutes * 60,
      completed: true,
      startedAt: startedAt,
      label: label,
    );
    await _keep(session);
    notifyListeners();
    return session;
  }

  Future<void> _keep(FocusSession session) async {
    for (final piece in session.split()) {
      _sessions.add(piece);
      _view = null;
      _perDay = null;
      try {
        await LocalStore.writeFocusSession(piece);
      } catch (e) {
        debugPrint('Could not save a focus session: $e');
      }
    }
  }

  List<FocusTask> get tasks => List.unmodifiable(_tasks);
  int get pendingTasks => _tasks.where((t) => !t.done).length;

  String get habitId => _habitId;
  String get label => _label;
  bool get isBreak => _isBreak;
  int get round => _round;
  bool get isPomodoro => _breakMinutes > 0;
  static const longBreakEvery = 4;
  int get _longBreakMinutes => LocalStore.setting('focusLongBreak', 0);
  bool get isLongBreak =>
      _isBreak && _longBreakMinutes > 0 && _round % longBreakEvery == 0;
  int get targetMinutes => _targetMinutes;
  int get targetSeconds => _targetMinutes * 60;

  bool get isActive => _open;
  bool get isRunning => _since != null;
  bool get isAwaiting => _awaiting;
  bool get isFinished => _open && !isPomodoro && reachedTarget;

  static const switchDelay = 5;

  int get switchIn => _switchIn;

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
    String label = '',
  }) {
    _habitId = habitId;
    _label = label;
    if (label.isNotEmpty) unawaited(rememberLabel(habitId, label));
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
    unawaited(FocusAudio.stopAlert());
    if (_since == null) return;
    _accumulated = elapsedAt(at ?? DateTime.now());
    _since = null;
    _stopTicker();
    _persist();
    _sync();
    notifyListeners();
    _soundOnPause = FocusAudio.playing.value;
    if (_soundOnPause) unawaited(FocusAudio.pause());
  }

  void resume({DateTime? at}) {
    if (_since != null) return;
    _since = at ?? DateTime.now();
    _startTicker();
    _persist();
    _sync();
    notifyListeners();
    if (!_soundOnPause) return;
    _soundOnPause = false;
    unawaited(FocusAudio.resume());
  }

  void continueNow({DateTime? at}) {
    if (!_awaiting && !(isPomodoro && reachedTarget)) return;
    _awaiting = false;
    unawaited(FocusAudio.stopAlert());
    _advancePhase(at: at);
  }

  void reset() {
    _awaiting = false;
    _switchIn = 0;
    unawaited(FocusAudio.stopAlert());
    _accumulated = 0;
    _since = isRunning ? DateTime.now() : null;
    _celebrated = false;
    if (isRunning) _startTicker();
    _persist();
    _sync();
    notifyListeners();
  }

  void addMinute() {
    if (!_open || isFlow) return;
    _awaiting = false;
    _switchIn = 0;
    unawaited(FocusAudio.stopAlert());
    if (reachedTarget) {
      _accumulated = targetSeconds;
      if (isRunning) _since = DateTime.now();
    }
    _targetMinutes++;
    _celebrated = false;
    if (isRunning) _startTicker();
    _persist();
    _sync();
    notifyListeners();
  }

  void skipBreak({DateTime? at}) {
    _awaiting = false;
    unawaited(FocusAudio.stopAlert());
    if (_isBreak) _advancePhase(at: at);
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
        return stop(
          completed: isFlow || elapsedAt(action.at) >= targetSeconds,
          at: action.at,
        );
      case FocusAction.minute:
        addMinute();
      case FocusAction.skip:
        skipBreak(at: action.at);
      case FocusAction.next:
        continueNow(at: action.at);
    }
    return null;
  }

  Future<FocusSession?> stop({required bool completed, DateTime? at}) async {
    final endedAt = at ?? DateTime.now();
    final dropped = isPomodoro &&
        !completed &&
        LocalStore.setting('focusWholeRounds', false);
    final seconds = _isBreak || dropped ? 0 : elapsedAt(endedAt);
    final habitId = _habitId;
    final label = _label;
    final target = _focusMinutes;
    _stopTicker();
    _awaiting = false;
    _switchIn = 0;
    unawaited(FocusAudio.stopAlert());
    if (FocusAudio.current.value.isNotEmpty) unawaited(FocusAudio.stop());
    _accumulated = 0;
    _since = null;
    _habitId = '';
    _label = '';
    _tasks.clear();
    _celebrated = false;
    _isBreak = false;
    _soundOnBreak = false;
    _soundOnPause = false;
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
      label: label,
    );
    await _keep(session);
    notifyListeners();
    return session;
  }

  Future<void> _saveRound(FocusSession session) async {
    await _keep(session);
    notifyListeners();
    onRoundSaved?.call(session);
  }

  void _advancePhase({DateTime? at}) {
    final endedAt = _phaseEnd;
    if (!_isBreak) {
      final seconds = elapsedAt(endedAt);
      if (seconds >= 30) {
        unawaited(
          _saveRound(
            FocusSession(
              id: const Uuid().v4(),
              habitId: _habitId,
              targetMinutes: _focusMinutes,
              seconds: seconds,
              completed: true,
              startedAt: endedAt.subtract(Duration(seconds: seconds)),
              label: _label,
            ),
          ),
        );
      }
    } else {
      _round++;
    }
    _isBreak = !_isBreak;
    _awaiting = false;
    _switchIn = 0;
    _targetMinutes = !_isBreak
        ? _focusMinutes
        : isLongBreak
        ? _longBreakMinutes
        : _breakMinutes;
    _accumulated = 0;
    _since = at ?? DateTime.now();
    _celebrated = false;
    _startTicker();
    _persist();
    _sync();
    notifyListeners();
    unawaited(_holdSound());
  }

  Future<void> _holdSound() async {
    try {
      if (_isBreak) {
        _soundOnBreak = FocusAudio.playing.value;
        if (_soundOnBreak) await FocusAudio.pause();
      } else if (_soundOnBreak) {
        _soundOnBreak = false;
        await FocusAudio.resume();
      }
    } catch (e) {
      debugPrint('Focus sound hold failed: $e');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_switchIn > 0) {
        if (--_switchIn == 0) return _advancePhase();
        _sync();
        return _tick();
      }
      if (!_celebrated && reachedTarget) {
        _celebrated = true;
        completedTick.value++;
        if (!isMobile) unawaited(_announceEnd(breakEnded: _isBreak));
        final always = isPomodoro && LocalStore.setting('focusHold', false);
        final hold = always || (isPomodoro && _isBreak);
        if (DateTime.now().difference(_phaseEnd).inSeconds < 60) {
          unawaited(
            FocusAudio.alert(
              LocalStore.setting('focusAlert', ''),
              loop: always,
            ),
          );
        }
        if (hold) {
          _awaiting = true;
          _stopTicker();
          _persist();
          _sync();
          notifyListeners();
        } else if (isPomodoro) {
          _switchIn = switchDelay;
          _sync();
        } else {
          _stopTicker();
          _sync();
          notifyListeners();
        }
      }
      _tick();
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

  Future<(String, String)> _endTexts({required bool breakEnded}) async {
    final strings = await NotificationService().localizations();
    if (breakEnded) return (strings.focus_break_over, strings.focus_notif_back);
    if (isPomodoro) return (strings.focus_done_title, strings.focus_notif_break);
    return (strings.focus_done_title, strings.focus_notif_body);
  }

  Future<void> _announceEnd({required bool breakEnded}) async {
    final (title, body) = await _endTexts(breakEnded: breakEnded);
    await NotificationService().showFocusEnd(
      title: title,
      body: body,
      habitId: _habitId,
    );
  }

  Future<void> _syncEndAlarm() async {
    final notifications = NotificationService();
    try {
      if (!_open || !isRunning) return await notifications.cancelFocusEnd();
      if (isFlow || reachedTarget || !isMobile) return;
      if (Platform.isAndroid) return await notifications.cancelFocusEnd();
      final (title, body) = await _endTexts(breakEnded: _isBreak);
      await notifications.scheduleFocusEnd(
        title: title,
        body: body,
        after: Duration(seconds: remainingSeconds),
      );
    } catch (e) {
      debugPrint('Focus end alarm failed: $e');
    }
  }

  Future<void> _pushed = Future.value();

  void _sync() {
    _pushed = _pushed.then((_) => _push());
  }

  Future<void> _push() async {
    unawaited(_syncEndAlarm());
    try {
      if (!_open) {
        await FocusService.hide();
        return;
      }
      final strings = await NotificationService().localizations();
      if (!_open) {
        await FocusService.hide();
        return;
      }
      final habit = _habitId.isEmpty ? null : LocalStore.habitName(_habitId);
      final name = _label.isEmpty
          ? habit
          : habit == null
          ? _label
          : '$habit · $_label';
      final done = _awaiting || _switchIn > 0 || (reachedTarget && !isPomodoro);
      final label = _awaiting
          ? strings.focus_continue
          : _switchIn > 0
          ? (_isBreak ? strings.focus_back_in : strings.focus_break_in)('$_switchIn')
          : done
          ? strings.focus_target_reached
          : _isBreak
              ? (isLongBreak ? strings.focus_long_break : strings.focus_break)
              : !isRunning
                  ? strings.focus_paused
                  : isFlow
                      ? strings.focus_flowtime
                      : strings.focus_notif_running;
      final phase = _awaiting
          ? 'waiting'
          : done
          ? 'done'
          : _isBreak
              ? 'break'
              : isRunning
                  ? 'running'
                  : 'paused';
      final (endTitle, endBody) = await _endTexts(breakEnded: _isBreak);
      final always = isPomodoro && LocalStore.setting('focusHold', false);
      await FocusService.show(
        habitId: _habitId,
        title: name ?? strings.focus,
        state: isPomodoro
            ? '$label  ·  ${strings.focus_round(_round)}'
            : label,
        phase: phase,
        running: isRunning && !done,
        done: done,
        countDown: !isFlow,
        seconds: displaySeconds,
        anchor: _anchorMs,
        total: isFlow ? 0 : targetSeconds,
        channelName: strings.focus_notif_channel,
        pauseLabel: strings.focus_pause,
        resumeLabel: strings.focus_resume,
        stopLabel: strings.focus_end,
        continueLabel: strings.focus_continue,
        skipLabel: strings.focus_skip_break,
        minuteLabel: '+${strings.minutes_short('1')}',
        endTitle: endTitle,
        endBody: endBody,
        hold: always || (isPomodoro && _isBreak),
        upcoming: isPomodoro ? _upcoming(strings, always: always) : const [],
      );
    } catch (e) {
      debugPrint('Focus notification sync failed: $e');
    }
  }

  List<Map<String, Object>> _upcoming(
    AppLocalizations strings, {
    required bool always,
  }) {
    final phases = <Map<String, Object>>[];
    var round = _round;
    var onBreak = _isBreak;
    for (var i = 0; i < 8; i++) {
      if (onBreak) round++;
      onBreak = !onBreak;
      final long =
          onBreak && _longBreakMinutes > 0 && round % longBreakEvery == 0;
      final minutes = !onBreak
          ? _focusMinutes
          : long
          ? _longBreakMinutes
          : _breakMinutes;
      final label = !onBreak
          ? strings.focus_notif_running
          : long
          ? strings.focus_long_break
          : strings.focus_break;
      phases.add({
        'total': minutes * 60,
        'state': '$label  ·  ${strings.focus_round(round)}',
        'phase': onBreak ? 'break' : 'running',
        'hold': always || onBreak,
        'endTitle': onBreak ? strings.focus_break_over : strings.focus_done_title,
        'endBody': onBreak ? strings.focus_notif_back : strings.focus_notif_break,
      });
    }
    return phases;
  }

  static const _labelsKey = 'focusLabels';
  static const maxLabels = 20;

  List<String> labelsFor(String habitId) {
    final saved = LocalStore.settingMap(_labelsKey)[habitId];
    return saved is List ? List<String>.from(saved) : const [];
  }

  Future<void> rememberLabel(String habitId, String label) async {
    final all = LocalStore.settingMap(_labelsKey);
    final labels = [
      label,
      ...labelsFor(habitId).where((l) => l != label),
    ].take(maxLabels).toList();
    all[habitId] = labels;
    await LocalStore.writeSetting(_labelsKey, all);
    notifyListeners();
  }

  Future<void> forgetLabel(String habitId, String label) async {
    final all = LocalStore.settingMap(_labelsKey);
    all[habitId] = labelsFor(habitId).where((l) => l != label).toList();
    await LocalStore.writeSetting(_labelsKey, all);
    notifyListeners();
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
          .where((s) => s.habitId == habitId && s.countedOn.dayKey == day.dayKey)
          .toList();

  Map<String, int> get _secondsPerDay => _perDay ??= _sumPerDay();

  Map<String, int> _sumPerDay() {
    final sums = <String, int>{};
    for (final session in _sessions) {
      final key = '${session.habitId}|${session.countedOn.dayKey}';
      sums[key] = (sums[key] ?? 0) + session.seconds;
    }
    return sums;
  }

  int secondsForHabitOnDay(String habitId, DateTime day) =>
      _secondsPerDay['$habitId|${day.dayKey}'] ?? 0;

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
