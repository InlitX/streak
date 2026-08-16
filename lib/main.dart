import 'dart:async';

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
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/services/focus_service.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/image_cleanup_service.dart';
import 'package:streak/services/notification_service.dart';
import 'package:streak/services/widget_action_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();
  await LocalStore.init();
  AppClock.cutoffHour = LocalStore.setting('dayCutoff', 0);
  await WidgetActionService.drain(LocalStore.readHabits());
  unawaited(ImageCleanupService.run());

  NotificationService.onOpenHabit = _openHabit;
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
    return null;
  });

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final pending = NotificationService().pendingHabitId;
    if (pending != null) {
      NotificationService().pendingHabitId = null;
      _openHabit(pending);
    }
    final launched = await _appChannel.invokeMethod<String>('consumeLaunchHabit');
    if (launched != null) _openHabit(launched);
    final focusOn = await _appChannel.invokeMethod<String>('consumeLaunchFocus');
    if (focusOn != null) _startFocus(focusOn);
    await drainFocusActions();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => CategoriesController()),
        ChangeNotifierProvider(create: (_) => NotesController()),
        ChangeNotifierProvider(create: (_) => TodosController()),
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
    await LocalStore.reloadHabits();
    final habits = LocalStore.readHabits();
    await WidgetActionService.drain(habits);
    await HomeWidgetService.sync(habits, renderIcons: false);
  } catch (e) {
    debugPrint('Widget action entrypoint failed: $e');
  }
  await channel.invokeMethod('done');
}
