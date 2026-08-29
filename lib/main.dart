import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/streak_app.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/services/focus_service.dart';
import 'package:streak/services/folder_sync.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/image_cleanup_service.dart';
import 'package:streak/services/notification_service.dart';
import 'package:streak/services/todos_widget_service.dart';
import 'package:streak/services/widget_action_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await initializeDateFormatting();
  await LocalStore.init();
  AppClock.cutoffHour = LocalStore.setting('dayCutoff', 0);
  await WidgetActionService.drain(
    LocalStore.readHabits(),
    todos: LocalStore.readTodos(),
  );
  await FolderSync.pull();
  unawaited(ImageCleanupService.run());

  NotificationService.onOpenHabit = _openHabit;
  NotificationService.onOpenTodos = _openTodos;
  FocusService.onPending = drainFocusActions;
  FocusService.listen();
  try {
    await NotificationService().initialize();
  } catch (e, s) {
    debugPrint('Startup init (notifications/widget) failed: $e\n$s');
  }

  _appChannel.setMethodCallHandler((call) async {
    if (call.method == 'openHabit') {
      final id = call.arguments as String?;
      if (id != null) _openHabit(id);
    }
    if (call.method == 'startFocus') {
      final id = call.arguments as String?;
      if (id != null) _startFocus(id);
    }
    if (call.method == 'openPage') {
      final page = call.arguments as String?;
      if (page != null) _openPage(page);
    }
    return null;
  });

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final pending = NotificationService().pendingHabitId;
    if (pending != null) {
      NotificationService().pendingHabitId = null;
      _openHabit(pending);
    }
    if (Platform.isAndroid) {
      final launched =
          await _appChannel.invokeMethod<String>('consumeLaunchHabit');
      if (launched != null) _openHabit(launched);
      final focusOn = await _appChannel.invokeMethod<String>('consumeLaunchFocus');
      if (focusOn != null) _startFocus(focusOn);
      final page = await _appChannel.invokeMethod<String>('consumeLaunchPage');
      if (page != null) _openPage(page);
    }
    await drainFocusActions();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => CategoriesController()),
        ChangeNotifierProvider(create: (_) => NotesController()),
        ChangeNotifierProvider(
          create: (_) {
            final controller = TodosController();
            TodosWidgetService.sync(controller.all);
            return controller;
          },
        ),
        ChangeNotifierProvider(create: (_) => FocusController()),
        ChangeNotifierProvider(
          create: (_) {
            final controller = HabitsController();
            HomeWidgetService.sync(controller.asMap);
            controller.rescheduleReminders();
            return controller;
          },
        ),
      ],
      child: const StreakApp(),
    ),
  );
}

const _appChannel = MethodChannel('streak/app_icon');

void _openHabit(String habitId) {
  AppNavigator.push(HabitDetailsPage(habitId: habitId), fade: true);
}

void _openTodos() {
  AppNavigator.push(const TodosPage(), fade: true);
}

void _openPage(String page) {
  if (page == 'todos') _openTodos();
  if (page == 'stats') AppNavigator.push(const StatisticsPage(), fade: true);
}

void _startFocus(String habitId) {
  final context = AppNavigator.key.currentContext;
  if (context == null) return;
  if (AppNavigator.isShowing(FocusPage.routeName)) return;
  if (context.read<FocusController>().isActive) {
    AppNavigator.push(const FocusPage(), fade: true, name: FocusPage.routeName);
    return;
  }
  final habit = context.read<HabitsController>().byId(habitId);
  if (habit == null) return;
  AppNavigator.push(
    FocusPage(
      startHabitId: habit.id,
      startMinutes: habit.focusMinutes,
      breakMinutes: habit.focusBreakMinutes,
    ),
    fade: true,
    name: FocusPage.routeName,
  );
}

@pragma('vm:entry-point')
Future<void> widgetActionEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('streak/widget_action');
  try {
    await initializeDateFormatting();
    await LocalStore.init();
    AppClock.cutoffHour = LocalStore.setting('dayCutoff', 0);
    await LocalStore.reloadHabits();
    final habits = LocalStore.readHabits();
    final todos = LocalStore.readTodos();
    await WidgetActionService.drain(habits, todos: todos);
    await HomeWidgetService.sync(habits, renderIcons: false);
    await TodosWidgetService.sync(todos);
    await NotificationService().rescheduleTodos(todos);
  } catch (e) {
    debugPrint('Widget action entrypoint failed: $e');
  }
  await channel.invokeMethod('done');
}
