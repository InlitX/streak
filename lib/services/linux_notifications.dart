import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class LinuxNotifications {
  LinuxNotifications(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  final _queue = <int, _Queued>{};
  Timer? _tick;

  static const _tickEvery = Duration(seconds: 20);

  void schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    String? payload,
    bool weekly = false,
  }) {
    _queue[id] = _Queued(title, body, when, details, payload, weekly);
    _tick ??= Timer.periodic(_tickEvery, (_) => _showDue());
  }

  void cancel(int id) => _queue.remove(id);

  void cancelAll() => _queue.clear();

  List<PendingNotificationRequest> get pending => [
        for (final entry in _queue.entries)
          PendingNotificationRequest(
            entry.key,
            entry.value.title,
            entry.value.body,
            entry.value.payload,
          ),
      ];

  Future<void> _showDue() async {
    final now = tz.TZDateTime.now(tz.local);
    for (final entry in _queue.entries.toList()) {
      final item = entry.value;
      if (item.when.isAfter(now)) continue;
      if (item.weekly) {
        _queue[entry.key] = item.nextAfter(now);
      } else {
        _queue.remove(entry.key);
      }
      await _plugin.show(
        entry.key,
        item.title,
        item.body,
        item.details,
        payload: item.payload,
      );
    }
  }
}

class _Queued {
  const _Queued(
    this.title,
    this.body,
    this.when,
    this.details,
    this.payload,
    this.weekly,
  );

  final String title;
  final String body;
  final tz.TZDateTime when;
  final NotificationDetails details;
  final String? payload;
  final bool weekly;

  _Queued nextAfter(tz.TZDateTime now) {
    var next = when;
    while (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day + 7,
        next.hour,
        next.minute,
      );
    }
    return _Queued(title, body, next, details, payload, weekly);
  }
}
