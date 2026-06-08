import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:streak/core/constants/motivational_quotes.dart';
import 'package:streak/core/database/local_store.dart';
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

  /// Lo setea la app para abrir el hábito al pulsar una notificación.
  static void Function(String habitId)? onOpenHabit;

  /// habitId de una notificación que abrió la app desde cero.
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

    // Status-bar icon: a transparent white silhouette (Android masks to alpha).
    const android = AndroidInitializationSettings('ic_stat_notify');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    // Si la app se abrió pulsando una notificación estando cerrada.
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

  Future<void> _schedule(Habit habit, Reminder reminder) async {
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

      // Cuerpo: mensaje personalizado o una frase motivacional aleatoria,
      // con un saludo usando el nombre del perfil si lo hay.
      final lang = LocalStore.setting('locale', '') == 'es' ? 'es' : 'en';
      var body = reminder.message.trim().isNotEmpty
          ? reminder.message.trim()
          : MotivationalQuotes.random(lang);
      final name = LocalStore.setting('profileName', '').trim();
      if (name.isNotEmpty) {
        body = (lang == 'es' ? 'Hola $name, ' : 'Hi $name, ') + body;
      }

      await _plugin.zonedSchedule(
        id,
        habit.name,
        body,
        when,
        NotificationDetails(
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
        ),
        payload: habit.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelFor(String habitId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.payload == habitId) await _plugin.cancel(n.id);
    }
  }

  int _notificationId(String habitId, String reminderId, int day) {
    final h = habitId.hashCode.abs() % 10000;
    final r = reminderId.hashCode.abs() % 100;
    return h * 1000 + r * 10 + day;
  }
}
