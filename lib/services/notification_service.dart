import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:streak/core/constants/motivational_quotes.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit Reminders';

  static void Function(String habitId)? onOpenHabit;

  String? pendingHabitId;

  bool _ready = false;

  void _handleResponse(NotificationResponse response) {
    final id = response.payload;
    if (id != null && id.isNotEmpty) onOpenHabit?.call(id);
  }

  Future<void> initialize() async {
    if (_ready) return;

    tz.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    const android = AndroidInitializationSettings('ic_stat_notify');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      pendingHabitId = launch!.notificationResponse?.payload;
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Reminders to keep your streaks alive',
            importance: Importance.max,
          ));
    }

    _ready = true;
  }

  Future<bool> requestPermissions() async {
    if (!await Permission.notification.isGranted) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }
    if (Platform.isAndroid) {
      final exact = await Permission.scheduleExactAlarm.status;
      if (!exact.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        if (!result.isGranted) return false;
      }
    }
    return true;
  }

  Future<void> scheduleFor(Habit habit) async {
    if (!_ready) await initialize();
    await cancelFor(habit.id);
    for (final reminder in habit.reminders) {
      await _schedule(habit, reminder);
    }
  }

  // Every-N-days has no OS repeat: schedule N one-shots, refreshed on launch.
  static const _intervalWindow = 24;

  Future<void> _schedule(Habit habit, Reminder reminder) async {
    final body = _bodyFor(reminder);
    if (reminder.isInterval) {
      await _scheduleInterval(habit, reminder, body);
    } else {
      await _scheduleWeekly(habit, reminder, body);
    }
  }

  String _bodyFor(Reminder reminder) {
    final lang = LocalStore.setting('locale', '') == 'es' ? 'es' : 'en';
    var body = reminder.message.trim().isNotEmpty
        ? reminder.message.trim()
        : MotivationalQuotes.random(lang);
    final name = LocalStore.setting('profileName', '').trim();
    if (name.isNotEmpty) {
      body = (lang == 'es' ? 'Hola $name, ' : 'Hi $name, ') + body;
    }
    return body;
  }

  Future<void> _scheduleWeekly(
      Habit habit, Reminder reminder, String body) async {
    for (final day in reminder.days) {
      final id = _notificationId(habit.id, reminder.id, day);
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      while (when.weekday != day) {
        when = when.add(const Duration(days: 1));
      }
      if (when.isBefore(now)) when = when.add(const Duration(days: 7));

      await _plugin.zonedSchedule(
        id,
        habit.name,
        body,
        when,
        _details(habit, body),
        payload: habit.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _scheduleInterval(
      Habit habit, Reminder reminder, String body) async {
    final every = reminder.everyDays;
    final now = tz.TZDateTime.now(tz.local);
    final todayEpoch = DateTime(now.year, now.month, now.day).epochDay;
    final anchor = reminder.anchorEpochDay ?? todayEpoch;

    final phase = ((todayEpoch - anchor) % every + every) % every;
    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (phase != 0) {
      first = first.add(Duration(days: every - phase));
    } else if (first.isBefore(now)) {
      first = first.add(Duration(days: every));
    }

    for (var i = 0; i < _intervalWindow; i++) {
      final when = first.add(Duration(days: every * i));
      await _plugin.zonedSchedule(
        _notificationId(habit.id, reminder.id, i),
        habit.name,
        body,
        when,
        _details(habit, body),
        payload: habit.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  NotificationDetails _details(Habit habit, String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to keep your streaks alive',
          importance: Importance.high,
          priority: Priority.high,
          color: habit.color,
          playSound: true,
          icon: 'ic_stat_notify',
          styleInformation: BigTextStyleInformation(body),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
      );

  Future<void> cancelFor(String habitId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.payload == habitId) await _plugin.cancel(n.id);
    }
  }

  // slot = ISO weekday (1..7) or occurrence index; both fit in 6 bits.
  int _notificationId(String habitId, String reminderId, int slot) {
    final h = habitId.hashCode.abs() % 10000;
    final r = reminderId.hashCode.abs() % 100;
    return (h * 100 + r) * 64 + slot;
  }
}
