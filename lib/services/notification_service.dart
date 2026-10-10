import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:streak/core/i18n/app_locale.dart';
import 'package:streak/core/constants/motivational_quotes.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/reminder.dart';
import 'package:streak/features/todos/data/todo.dart';
import 'package:streak/services/reminder_schedule.dart';
import 'package:streak/l10n/app_localizations.dart';
import 'package:streak/l10n/app_localizations_en.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/in_app_notifications.dart';
import 'package:streak/services/todos_widget_service.dart';
import 'package:streak/services/widget_icon_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();
  late final _inApp = InAppNotifications(_plugin);
  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit Reminders';
  static String get windowsAppId =>
      isPortable ? 'com.streak.app.portable' : 'com.streak.app';

  static const actionDone = 'habit_done';
  static const actionSnooze = 'habit_snooze';
  static const actionAdd = 'habit_add';
  static const actionTodoDone = 'todo_done';

  static const _amountInput = 'amount';

  static bool takesAmount(Habit habit) =>
      habit.kind == HabitKind.quantitative || habit.effectiveTarget > 1;

  static bool armedToday(String key) {
    final today = AppClock.today().dayKey;
    if (LocalStore.setting(key, '') == today) return true;
    LocalStore.writeSetting(key, today);
    return false;
  }

  static const _categoryHabit = 'habit';
  static const _categoryAmount = 'habit_amount';
  static const _categoryNegative = 'habit_negative';
  static const _categoryTodo = 'todo';

  static String _categoryFor(Habit habit) => habit.kind == HabitKind.negative
      ? _categoryNegative
      : takesAmount(habit)
          ? _categoryAmount
          : _categoryHabit;

  List<DarwinNotificationCategory> _categories(AppLocalizations strings) {
    final done =
        DarwinNotificationAction.plain(actionDone, strings.notif_action_done);
    final snooze = DarwinNotificationAction.plain(
      actionSnooze,
      strings.notif_action_snooze,
    );
    final add = DarwinNotificationAction.text(
      actionAdd,
      strings.notif_action_add,
      buttonTitle: strings.notif_action_add,
      placeholder: strings.notif_action_add_hint,
    );
    return [
      DarwinNotificationCategory(_categoryHabit, actions: [done, snooze]),
      DarwinNotificationCategory(_categoryAmount, actions: [done, add, snooze]),
      DarwinNotificationCategory(_categoryNegative, actions: [snooze]),
      DarwinNotificationCategory(
        _categoryTodo,
        actions: [
          DarwinNotificationAction.plain(
            actionTodoDone,
            strings.notif_action_done,
          ),
        ],
      ),
    ];
  }

  static void Function(String habitId)? onOpenHabit;
  static void Function()? onOpenTodos;
  static void Function()? onHabitsChanged;
  static void Function()? onTodosChanged;

  static const _todoPayload = 'todo:';

  String? pendingHabitId;

  bool _ready = false;
  bool _knownToWindows = false;

  static (String?, String?, String?) _read(NotificationResponse response) {
    final payload = response.payload;
    if (!Platform.isWindows || payload == null) {
      return (payload, response.actionId, response.input);
    }
    final split = payload.indexOf(':');
    final action = split < 0 ? null : payload.substring(0, split);
    if (!NotificationActions.handles(action)) return (payload, null, null);
    final input = response.data[_amountInput];
    return (payload.substring(split + 1), action, input is String ? input : null);
  }

  static String _windowsArguments(String action, Habit habit) =>
      '$action:${habit.id}';

  void _handleResponse(NotificationResponse response) {
    final (id, actionId, input) = _read(response);
    if (id == null || id.isEmpty) return;
    if (id.startsWith(_todoPayload)) {
      if (actionId == actionTodoDone) {
        NotificationActions.apply(actionId!, id)
            .then((_) => onTodosChanged?.call());
      } else {
        onOpenTodos?.call();
      }
      return;
    }
    if (NotificationActions.handles(actionId)) {
      NotificationActions.apply(actionId!, id, input, response.id)
          .then((_) => onHabitsChanged?.call());
      return;
    }
    onOpenHabit?.call(id);
  }

  static tz.Location _localZone(String reported) {
    final names = [if (Platform.isLinux) _linkedZone(), reported];
    for (final name in names.whereType<String>()) {
      try {
        return tz.getLocation(name);
      } catch (_) {}
    }
    return tz.UTC;
  }

  static String? _linkedZone() {
    try {
      final target = Link('/etc/localtime').targetSync();
      final at = target.indexOf('zoneinfo/');
      return at < 0 ? null : target.substring(at + 'zoneinfo/'.length);
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (_ready) return;

    tz.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(_localZone(zone.identifier));

    const android = AndroidInitializationSettings('ic_stat_notify');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: _categories(await localizations()),
    );
    final windows = WindowsInitializationSettings(
      appName: 'Streak',
      appUserModelId: windowsAppId,
      guid: 'cfb32a7d-9c06-495b-8afa-df8829d33edc',
      iconPath: [
        File(Platform.resolvedExecutable).parent.path,
        'data',
        'flutter_assets',
        'assets',
        'icon.png',
      ].join(Platform.pathSeparator),
    );
    final linux = LinuxInitializationSettings(
      defaultActionName: 'Open',
      defaultIcon: AssetsLinuxIcon('assets/icon.png'),
    );
    await _plugin.initialize(
      InitializationSettings(
        android: android,
        iOS: darwin,
        windows: windows,
        linux: linux,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationActionEntrypoint,
    );

    final launch =
        Platform.isLinux ? null : await _plugin.getNotificationAppLaunchDetails();
    final opened = launch?.didNotificationLaunchApp ?? false
        ? launch!.notificationResponse
        : null;
    final (launchId, launchAction, launchInput) =
        opened == null ? (null, null, null) : _read(opened);
    final launchedByAction = NotificationActions.handles(launchAction);
    if (!launchedByAction) pendingHabitId = launchId;

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

    if (isPortable) await _plugin.cancelAll();
    await _repairStore();

    _ready = true;

    if (launchedByAction && launchId != null) {
      await NotificationActions.apply(launchAction!, launchId, launchInput);
    }
  }

  Future<void> _repairStore() async {
    try {
      await _pending();
    } catch (e) {
      debugPrint('Scheduled notification store unreadable, resetting: $e');
      await cancelAll();
    }
  }

  Future<bool> requestNotifications() async {
    if (Platform.isLinux || Platform.isWindows) return true;
    try {
      if (await Permission.notification.isGranted) return true;
      return (await Permission.notification.request()).isGranted;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!await requestNotifications()) return false;
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
    if (habit.isOnVacation) {
      await cancelFor(habit.id);
      return;
    }
    final live = <int>{};
    for (final reminder in habit.reminders) {
      try {
        live.addAll(await _schedule(habit, reminder));
      } catch (e) {
        debugPrint('Scheduling ${habit.name} / ${reminder.id} failed: $e');
      }
    }
    await _cancelExcept(habit.id, live);
  }

  static int get _intervalWindow => Platform.isIOS ? 8 : 24;

  Future<Set<int>> _schedule(Habit habit, Reminder reminder) async {
    final strings = await localizations();
    final body = _bodyFor(habit, reminder, strings);
    if (habit.interval == HabitInterval.everyXDays) {
      return _scheduleOnHabitDays(habit, reminder, body, strings);
    }
    if (reminder.isHourly) {
      return _scheduleHourly(habit, reminder, body, strings);
    }
    return reminder.isInterval
        ? _scheduleInterval(habit, reminder, body, strings)
        : _scheduleWeekly(habit, reminder, body, strings);
  }

  Future<AppLocalizations> localizations() async {
    final tag = LocalStore.setting('locale', '').trim();
    final locale = pickLocale(
      tag.isEmpty ? PlatformDispatcher.instance.locales : [_localeOf(tag)],
    );
    try {
      return await AppLocalizations.delegate.load(locale);
    } catch (_) {
      return AppLocalizationsEn();
    }
  }

  Locale _localeOf(String tag) {
    final parts = tag.split(RegExp('[_-]'));
    return parts.length > 1 ? Locale(parts.first, parts[1]) : Locale(parts.first);
  }

  String _bodyFor(Habit habit, Reminder? reminder, AppLocalizations strings) {
    final lang = strings.localeName == 'es' ? 'es' : 'en';
    final message = reminder?.message.trim() ?? '';
    final quotesOff = LocalStore.setting('quoteSource', 0) == 3;
    var body = message.isNotEmpty
        ? message
        : (quotesOff ? '' : MotivationalQuotes.random(lang));
    final name = LocalStore.setting('profileName', '').trim();
    if (name.isNotEmpty && body.isNotEmpty) {
      body = (lang == 'es' ? 'Hola $name, ' : 'Hi $name, ') + body;
    }
    final streak = habit.currentStreak;
    if (streak > 0) {
      final line = switch (habit.interval) {
        HabitInterval.weekly => strings.notif_streak_week('$streak'),
        HabitInterval.monthly => strings.notif_streak_month('$streak'),
        _ => strings.notif_streak('$streak'),
      };
      body = '$body\n$line';
    }
    return body;
  }

  bool _quietToday(Habit habit) =>
      LocalStore.setting('quietWhenDone', true) &&
      habit.silencesRemindersOn(AppClock.now());

  tz.TZDateTime _firstMoment(Habit habit) {
    final now = tz.TZDateTime.now(tz.local);
    if (!_quietToday(habit)) return now;
    final today = AppClock.today();
    final tomorrow = tz.TZDateTime(
      tz.local,
      today.year,
      today.month,
      today.day + 1,
      AppClock.cutoffHour,
    );
    return tomorrow.isAfter(now) ? tomorrow : now;
  }

  Future<void> dismissShown(Habit habit) async {
    if (!Platform.isAndroid || !_quietToday(habit)) return;
    try {
      final shown = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();
      final mine = _idsOf(habit);
      final ids = [
        for (final notification in shown ?? const <ActiveNotification>[])
          if (mine.contains(notification.id)) notification.id!,
      ];
      if (ids.isEmpty) return;
      await const MethodChannel('streak/app_icon')
          .invokeMethod('dismissNotifications', {'ids': ids});
    } catch (e) {
      debugPrint('Could not dismiss the reminders of ${habit.name}: $e');
    }
  }

  Set<int> _idsOf(Habit habit) => {
        for (final reminder in habit.reminders) ...{
          for (var slot = 0; slot < ReminderSchedule.slotsPerReminder; slot++)
            for (var week = 1; week <= ReminderSchedule.quietWeeks; week++)
              ReminderSchedule.quietId(
                _notificationId(habit.id, reminder.id, slot),
                week,
              ),
        },
        _snoozeId(habit.id),
      };

  Future<Set<int>> _scheduleHourly(Habit habit, Reminder reminder, String body,
      AppLocalizations strings) async {
    final ids = <int>{};
    final daily = reminder.days.length == 7 &&
        Iterable<int>.generate(7, (i) => i + 1).every(habit.ringsOnWeekday);
    final days = daily
        ? const [1]
        : [for (final day in reminder.days) if (habit.ringsOnWeekday(day)) day];
    final cap = ReminderSchedule.hourlyCap(days.length);
    final slots = ReminderSchedule.hourlySlots(
      hour: reminder.hour,
      minute: reminder.minute,
      everyHours: reminder.everyHours,
      until: reminder.untilMinute,
      cap: cap,
    );
    final now = tz.TZDateTime.now(tz.local);
    final from = _firstMoment(habit);

    for (final (index, day) in days.indexed) {
      for (var slot = 0; slot < slots.length; slot++) {
        final next = daily
            ? ReminderSchedule.nextDaily(
                now: now,
                hour: slots[slot] ~/ 60,
                minute: slots[slot] % 60,
              )
            : ReminderSchedule.nextWeekly(
                now: now,
                weekday: day,
                hour: slots[slot] ~/ 60,
                minute: slots[slot] % 60,
              );
        ids.addAll(await _scheduleRepeating(
          _notificationId(habit.id, reminder.id, index * cap + slot),
          habit,
          body,
          strings,
          next,
          from,
          daily: daily,
        ));
      }
    }
    return ids;
  }

  Future<Set<int>> _scheduleWeekly(Habit habit, Reminder reminder, String body,
      AppLocalizations strings) async {
    final ids = <int>{};
    final now = tz.TZDateTime.now(tz.local);
    final from = _firstMoment(habit);
    final daily = _repeatsDaily(habit, reminder);
    for (final day in daily ? const [1] : reminder.days) {
      if (!habit.ringsOnWeekday(day)) continue;
      final next = daily
          ? ReminderSchedule.nextDaily(
              now: now,
              hour: reminder.hour,
              minute: reminder.minute,
            )
          : ReminderSchedule.nextWeekly(
              now: now,
              weekday: day,
              hour: reminder.hour,
              minute: reminder.minute,
            );
      ids.addAll(await _scheduleRepeating(
        _notificationId(habit.id, reminder.id, day),
        habit,
        body,
        strings,
        next,
        from,
        daily: daily,
      ));
    }
    return ids;
  }

  bool _repeatsDaily(Habit habit, Reminder reminder) =>
      Platform.isIOS &&
      reminder.days.length == 7 &&
      Iterable<int>.generate(7, (i) => i + 1).every(habit.ringsOnWeekday);

  Future<Set<int>> _scheduleRepeating(
    int id,
    Habit habit,
    String body,
    AppLocalizations strings,
    DateTime next,
    tz.TZDateTime from, {
    bool daily = false,
  }) async {
    final when = tz.TZDateTime.from(next, tz.local);
    if (Platform.isWindows && !isPortable && !when.isBefore(from)) {
      final details = await _details(habit, body, strings);
      final ids = <int>{};
      for (var turn = 1; turn <= (daily ? 14 : 8); turn++) {
        final turnId = ReminderSchedule.quietId(id, turn);
        ids.add(turnId);
        await _zonedSchedule(
          turnId,
          habit.name,
          body,
          tz.TZDateTime.from(
            DateTime(
              next.year,
              next.month,
              next.day + (daily ? 1 : 7) * (turn - 1),
              next.hour,
              next.minute,
            ),
            tz.local,
          ),
          details,
          payload: habit.id,
        );
      }
      return ids;
    }
    if (!when.isBefore(from)) {
      await _zonedSchedule(
        id,
        habit.name,
        body,
        when,
        await _details(habit, body, strings),
        payload: habit.id,
        matchDateTimeComponents: daily
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
      return {id};
    }
    final ids = <int>{};
    for (var week = 1; week <= ReminderSchedule.quietWeeks; week++) {
      final quietId = ReminderSchedule.quietId(id, week);
      ids.add(quietId);
      await _zonedSchedule(
        quietId,
        habit.name,
        body,
        tz.TZDateTime.from(
          DateTime(
            next.year,
            next.month,
            next.day + (daily ? 1 : 7) * week,
            next.hour,
            next.minute,
          ),
          tz.local,
        ),
        await _details(habit, body, strings),
        payload: habit.id,
      );
    }
    return ids;
  }

  Future<Set<int>> _scheduleOnHabitDays(Habit habit, Reminder reminder,
      String body, AppLocalizations strings) async {
    final slots = reminder.isHourly
        ? ReminderSchedule.hourlySlots(
            hour: reminder.hour,
            minute: reminder.minute,
            everyHours: reminder.everyHours,
            until: reminder.untilMinute,
          )
        : [reminder.hour * 60 + reminder.minute];
    final moments = ReminderSchedule.onHabitDays(
      from: _firstMoment(habit),
      due: (day) => !habit.isOffDay(day),
      slots: slots,
      limit: Platform.isIOS ? 8 : ReminderSchedule.slotsPerReminder,
    );
    final ids = <int>{};
    for (final (index, at) in moments.indexed) {
      final id = _notificationId(habit.id, reminder.id, index);
      ids.add(id);
      await _zonedSchedule(
        id,
        habit.name,
        body,
        tz.TZDateTime.from(at, tz.local),
        await _details(habit, body, strings),
        payload: habit.id,
      );
    }
    return ids;
  }

  Future<Set<int>> _scheduleInterval(Habit habit, Reminder reminder, String body,
      AppLocalizations strings) async {
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

    final from = _firstMoment(habit);
    final ids = <int>{};
    for (var i = 0; i < _intervalWindow; i++) {
      final when = first.add(Duration(days: every * i));
      if (when.isBefore(from)) continue;
      if (!habit.ringsOnWeekday(when.weekday)) continue;
      final id = _notificationId(habit.id, reminder.id, i);
      ids.add(id);
      await _zonedSchedule(
        id,
        habit.name,
        body,
        when,
        await _details(habit, body, strings),
        payload: habit.id,
      );
    }
    return ids;
  }

  Future<List<WindowsImage>> _windowsLogo(Habit? habit) async {
    if (habit == null) return const [];
    final logo =
        await WidgetIconService.badge(habit.icon, habit.color.toARGB32());
    if (logo == null) return const [];
    return [
      WindowsImage(
        Uri.file(logo, windows: true),
        altText: habit.name,
        placement: WindowsImagePlacement.appLogoOverride,
        crop: WindowsImageCrop.circle,
      ),
    ];
  }

  Future<WindowsNotificationDetails?> _windowsDetails(
    Habit habit,
    AppLocalizations strings,
  ) async {
    if (!Platform.isWindows) return null;
    final amount = takesAmount(habit);
    return WindowsNotificationDetails(
      images: await _windowsLogo(habit),
      inputs: [
        if (amount)
          WindowsTextInput(
            id: _amountInput,
            placeHolderContent: strings.notif_action_add_hint,
          ),
      ],
      actions: [
        if (habit.kind != HabitKind.negative)
          WindowsAction(
            content: strings.notif_action_done,
            arguments: _windowsArguments(actionDone, habit),
          ),
        if (amount)
          WindowsAction(
            content: strings.notif_action_add,
            arguments: _windowsArguments(actionAdd, habit),
            inputId: _amountInput,
          ),
        WindowsAction(
          content: strings.notif_action_snooze,
          arguments: _windowsArguments(actionSnooze, habit),
        ),
      ],
    );
  }

  Future<NotificationDetails> _details(
    Habit habit,
    String body,
    AppLocalizations strings,
  ) async =>
      NotificationDetails(
        windows: await _windowsDetails(habit, strings),
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
          actions: [
            if (habit.kind != HabitKind.negative)
              AndroidNotificationAction(
                actionDone,
                strings.notif_action_done,
                showsUserInterface: false,
                cancelNotification: true,
              ),
            if (takesAmount(habit))
              AndroidNotificationAction(
                actionAdd,
                strings.notif_action_add,
                showsUserInterface: false,
                cancelNotification: true,
                inputs: [
                  AndroidNotificationActionInput(
                    label: strings.notif_action_add_hint,
                  ),
                ],
              ),
            AndroidNotificationAction(
              actionSnooze,
              strings.notif_action_snooze,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: _categoryFor(habit),
          threadIdentifier: habit.id,
        ),
      );

  Future<void> snooze(Habit habit) async {
    if (!_ready) await initialize();
    final reminder = habit.reminders.isEmpty ? null : habit.reminders.first;
    final strings = await localizations();
    final body = _bodyFor(habit, reminder, strings);
    final minutes = reminder?.snoozeMinutes ?? Reminder.defaultSnoozeMinutes;
    await _zonedSchedule(
      _snoozeId(habit.id),
      habit.name,
      body,
      tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes)),
      await _details(habit, body, strings),
      payload: habit.id,
    );
  }

  static const _focusEndId = -987654;

  Future<void> scheduleFocusEnd({
    required String title,
    required String body,
    required Duration after,
  }) async {
    if (!_ready) await initialize();
    await _cancel(_focusEndId);
    if (after.inSeconds <= 0) return;
    try {
      await _zonedSchedule(
        _focusEndId,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(after),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Reminders to keep your streaks alive',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> showFocusEnd({
    required String title,
    required String body,
    String habitId = '',
  }) async {
    if (!_ready) await initialize();
    try {
      final details = Platform.isWindows
          ? NotificationDetails(
              windows: WindowsNotificationDetails(
                images: await _windowsLogo(LocalStore.habit(habitId)),
              ),
            )
          : null;
      await _plugin.show(_focusEndId, title, body, details);
    } catch (e) {
      debugPrint('Focus end notice failed: $e');
    }
  }

  Future<void> cancelFocusEnd() async {
    try {
      await _cancel(_focusEndId);
    } catch (_) {}
  }

  int _snoozeId(String habitId) => -(habitId.hashCode.abs() % 1000000) - 1;

  Future<void> confirm(Habit habit, String text, int id) async {
    if (!Platform.isAndroid) return;
    await _plugin.show(
      id,
      habit.name,
      text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          onlyAlertOnce: true,
          color: habit.color,
          icon: 'ic_stat_notify',
          timeoutAfter: 4000,
        ),
      ),
      payload: habit.id,
    );
  }

  Future<void> scheduleTodo(Todo todo) async {
    try {
      await _scheduleTodo(todo);
    } catch (e) {
      debugPrint('Scheduling to-do ${todo.id} failed: $e');
    }
  }

  Future<void> _scheduleTodo(Todo todo) async {
    if (!_ready) await initialize();
    final id = ReminderSchedule.todoNotificationId(todo.id);
    await _cancel(id);

    final at = ReminderSchedule.todoFireAt(
      now: DateTime.now(),
      done: todo.done,
      due: todo.due,
      minutes: todo.minutes,
    );
    if (at == null) return;

    final strings = await localizations();
    await _zonedSchedule(
      id,
      todo.title,
      todo.body.isEmpty ? strings.todos : todo.body,
      tz.TZDateTime.from(at, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to keep your streaks alive',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(todo.body),
          actions: [
            AndroidNotificationAction(
              actionTodoDone,
              strings.notif_action_done,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(categoryIdentifier: _categoryTodo),
        windows: Platform.isWindows
            ? WindowsNotificationDetails(
                actions: [
                  WindowsAction(
                    content: strings.notif_action_done,
                    arguments: '$actionTodoDone:$_todoPayload${todo.id}',
                  ),
                ],
              )
            : null,
      ),
      payload: '$_todoPayload${todo.id}',
    );
  }

  Future<void> cancelTodo(String todoId) async {
    try {
      if (!_ready) await initialize();
      await _cancel(ReminderSchedule.todoNotificationId(todoId));
    } catch (e) {
      debugPrint('Cancelling to-do $todoId failed: $e');
    }
  }

  Future<void> rescheduleTodos(List<Todo> todos) async {
    for (final todo in todos.toList()) {
      await scheduleTodo(todo);
    }
  }

  Future<void> cancelFor(String habitId) async {
    await _cancelExcept(habitId, const {});
  }

  Future<void> cancelAll() async {
    if (_queuesInApp) _inApp.cancelAll();
    await _plugin.cancelAll();
  }

  Future<void> _cancelExcept(String habitId, Set<int> keep) async {
    final pending = await _pending();
    for (final n in pending) {
      if (n.payload == habitId && !keep.contains(n.id)) {
        await _cancel(n.id);
      }
    }
  }

  Future<void> _zonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    NotificationDetails details, {
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (_queuesInApp) {
      _inApp.schedule(
        id: id,
        title: title,
        body: body,
        when: when,
        details: details,
        payload: payload,
        repeatDays: switch (matchDateTimeComponents) {
          null => 0,
          DateTimeComponents.time => 1,
          _ => 7,
        },
      );
      return;
    }
    if (Platform.isWindows) await _introduceToWindows();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  static const _windowsReadyId = -987653;

  Future<void> _introduceToWindows() async {
    if (_knownToWindows || LocalStore.setting('windowsToastsReady', false)) return;
    _knownToWindows = true;
    try {
      final strings = await localizations();
      await _plugin.show(
        _windowsReadyId,
        strings.reminders_ready_title,
        strings.reminders_ready_body,
        NotificationDetails(
          windows: WindowsNotificationDetails(images: await _windowsLogo(null)),
        ),
      );
      await LocalStore.writeSetting('windowsToastsReady', true);
    } catch (e) {
      _knownToWindows = false;
      debugPrint('Could not introduce Streak to Windows: $e');
    }
  }

  bool get _queuesInApp => Platform.isLinux || isPortable;

  Future<void> _cancel(int id) async {
    if (_queuesInApp) _inApp.cancel(id);
    await _plugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> _pending() =>
      _queuesInApp
          ? Future.value(_inApp.pending)
          : _plugin.pendingNotificationRequests();

  int _notificationId(String habitId, String reminderId, int slot) =>
      ReminderSchedule.notificationId(habitId, reminderId, slot);
}

class NotificationActions {
  const NotificationActions._();

  static bool handles(String? actionId) =>
      actionId == NotificationService.actionDone ||
      actionId == NotificationService.actionSnooze ||
      actionId == NotificationService.actionAdd ||
      actionId == NotificationService.actionTodoDone;

  static Future<void> apply(
    String actionId,
    String habitId, [
    String? input,
    int? notificationId,
  ]) async {
    try {
      await LocalStore.init();
      AppClock.cutoffHour = LocalStore.setting('dayCutoff', 0);
      if (actionId == NotificationService.actionTodoDone) {
        await _finishTodo(habitId);
        return;
      }
      await LocalStore.reloadHabits();
      final habits = LocalStore.readHabits();
      final habit = habits[habitId];
      if (habit == null) return;

      if (actionId == NotificationService.actionSnooze) {
        await NotificationService().snooze(habit);
        return;
      }

      final today = AppClock.today();
      final text = input?.trim() ?? '';
      final amount =
          habit.isTimeAmount ? clockMinutes(text) : double.tryParse(text);

      final Map<String, Completion> completions;
      if (actionId == NotificationService.actionAdd) {
        if (amount == null || amount <= 0) return;
        completions = CompletionOps.addProgress(habit, today, amount);
      } else if (habit.isCompletedOn(today)) {
        return;
      } else if (habit.blocksManualCheck(today)) {
        return;
      } else if (NotificationService.takesAmount(habit)) {
        completions =
            CompletionOps.addProgress(habit, today, habit.incrementAmount);
      } else {
        completions = CompletionOps.toggle(habit, today);
      }
      final updated = habit.copyWith(completions: completions);

      if (actionId == NotificationService.actionAdd && notificationId != null) {
        final done = completions[today.dayKey]?.count ?? 0;
        final goal = updated.effectiveTarget;
        await NotificationService().confirm(
          updated,
          goal > 0
              ? '${updated.amountText(done)} / ${updated.amountText(goal)}'
              : updated.amountText(done),
          notificationId,
        );
      }

      await LocalStore.writeHabit(updated);
      habits[habitId] = updated;
      if (habit.fromLastDone ||
          habit.silencesRemindersOn(today) !=
              updated.silencesRemindersOn(today)) {
        await NotificationService().scheduleFor(updated);
      }
      await HomeWidgetService.sync(habits, renderIcons: false);
    } catch (e) {
      debugPrint('Notification action failed: $e');
    }
  }

  static Future<void> _finishTodo(String payload) async {
    if (!payload.startsWith(NotificationService._todoPayload)) return;
    await LocalStore.reloadTodos();
    final id = payload.substring(NotificationService._todoPayload.length);
    final todos = LocalStore.readTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index == -1 || todos[index].done) return;
    final done = todos[index].copyWith(done: true, doneAt: DateTime.now());
    todos[index] = done;
    await LocalStore.writeTodo(done);
    await TodosWidgetService.sync(todos);
  }
}

@pragma('vm:entry-point')
void notificationActionEntrypoint(NotificationResponse response) {
  final habitId = response.payload;
  final actionId = response.actionId;
  if (habitId == null || habitId.isEmpty) return;
  if (!NotificationActions.handles(actionId)) return;
  WidgetsFlutterBinding.ensureInitialized();
  NotificationActions.apply(actionId!, habitId, response.input, response.id);
}
