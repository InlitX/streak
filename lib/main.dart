import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/streak_app.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/habits/data/completion_ops.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStore.init();

  // Non-critical at startup: don't let a failure black-screen the app.
  NotificationService.onOpenHabit = _openHabit;
  try {
    await NotificationService().initialize();
    HomeWidget.registerInteractivityCallback(_widgetCallback);
  } catch (e, s) {
    debugPrint('Startup init (notifications/widget) failed: $e\n$s');
  }

  // A per-habit widget tap opens that habit: warm start pushes 'openHabit'.
  _appChannel.setMethodCallHandler((call) async {
    if (call.method == 'openHabit') {
      final id = call.arguments as String?;
      if (id != null) _openHabit(id);
    }
    return null;
  });

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final pending = NotificationService().pendingHabitId;
    if (pending != null) {
      NotificationService().pendingHabitId = null;
      _openHabit(pending);
    }
    // Cold start: pull the habit the app was launched for, if any.
    final launched = await _appChannel.invokeMethod<String>('consumeLaunchHabit');
    if (launched != null) _openHabit(launched);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => CategoriesController()),
        ChangeNotifierProvider(
          create: (_) {
            final controller = HabitsController();
            HomeWidgetService.sync(controller.asMap);
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

@pragma('vm:entry-point')
Future<void> _widgetCallback(Uri? uri) async {
  if (uri == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  // This isolate can be reused across taps; drop any stale cached box.
  await LocalStore.reloadHabits();

  final habitId = uri.queryParameters['habitId'];
  final dayIndex = int.tryParse(uri.queryParameters['dayIndex'] ?? '');
  if (habitId == null || dayIndex == null) return;

  final habits = LocalStore.readHabits();
  final habit = habits[habitId];
  if (habit == null) return;

  final target =
      DateTime.now().subtract(Duration(days: 6 - dayIndex)).atMidnight;

  // No dialog from the widget, so a relapse tap toggles straight away.
  final action = uri.queryParameters['action'] ?? 'toggle';
  final delta = int.tryParse(uri.queryParameters['delta'] ?? '') ??
      habit.incrementAmount;
  final completions = switch (action) {
    'relapse' => habit.completions.containsKey(target.dayKey)
        ? CompletionOps.clearRelapse(habit, target)
        : CompletionOps.logRelapse(habit, target),
    'progress' => CompletionOps.addProgress(habit, target, delta),
    _ => CompletionOps.toggle(habit, target),
  };

  final updated = habit.copyWith(completions: completions);
  habits[habitId] = updated;
  await LocalStore.writeHabit(updated);
  await HomeWidgetService.sync(habits);
}
