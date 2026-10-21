import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

enum HealthAccess { unsupported, denied, granted }

class HealthSteps {
  const HealthSteps._();

  static const _channel = MethodChannel('streak/health');
  static const _days = 7;
  static Future<void>? _running;

  static Future<HealthAccess> access() async {
    if (!Platform.isAndroid) return HealthAccess.unsupported;
    try {
      final status = await _channel.invokeMethod<String>('status');
      return HealthAccess.values.asNameMap()[status] ?? HealthAccess.unsupported;
    } on PlatformException {
      return HealthAccess.unsupported;
    } on MissingPluginException {
      return HealthAccess.unsupported;
    }
  }

  static Future<bool> request() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('request') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> openSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openSettings') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> sync(HabitsController habits) =>
      _running ??= _sync(habits).whenComplete(() => _running = null);

  static Future<void> _sync(HabitsController habits) async {
    final linked = habits.habits.where((h) => h.readsSteps).toList();
    if (linked.isEmpty || await access() != HealthAccess.granted) return;
    final today = AppClock.today();
    final days = [for (var i = _days - 1; i >= 0; i--) today.addDays(-i)];
    final now = DateTime.now().millisecondsSinceEpoch;
    final ranges = [
      for (final day in days)
        [_start(day), math.max(_start(day) + 1, math.min(_start(day.addDays(1)), now))],
    ];
    List<int>? counts;
    try {
      counts = await _channel.invokeListMethod<int>('readSteps', {'ranges': ranges});
    } on PlatformException {
      return;
    }
    if (counts == null || counts.length != days.length) return;
    for (final habit in linked) {
      final floor = habit.createdAt.atMidnight;
      await habits.logSteps(habit.id, {
        for (var i = 0; i < days.length; i++)
          if (counts[i] > 0 && !days[i].isBefore(floor)) days[i]: counts[i].toDouble(),
      });
    }
  }

  static int _start(DateTime day) =>
      DateTime(day.year, day.month, day.day, AppClock.cutoffHour)
          .millisecondsSinceEpoch;
}
