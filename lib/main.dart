import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/streak_app.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/habits/data/completion.dart';
import 'package:streak/features/habits/pages/habit_details_page.dart';
import 'package:streak/features/habits/state/categories_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStore.init();

  // Abrir el hábito al pulsar su notificación. La inicialización de
  // notificaciones/widget no es crítica para arrancar: si falla (p. ej. un
  // recurso de icono ausente), la capturamos para no abortar `main()` antes de
  // `runApp` y dejar la app en pantalla negra.
  NotificationService.onOpenHabit = _openHabit;
  try {
    await NotificationService().initialize();
    HomeWidget.registerInteractivityCallback(_widgetCallback);
  } catch (e, s) {
    debugPrint('Startup init (notifications/widget) failed: $e\n$s');
  }

  // Si la app arrancó desde una notificación, navega tras el primer frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final pending = NotificationService().pendingHabitId;
    if (pending != null) {
      NotificationService().pendingHabitId = null;
      _openHabit(pending);
    }
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

void _openHabit(String habitId) {
  AppNavigator.push(HabitDetailsPage(habitId: habitId), fade: true);
}

@pragma('vm:entry-point')
Future<void> _widgetCallback(Uri? uri) async {
  if (uri == null) return;

  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  // Force a fresh read from disk: this isolate may be reused across taps and
  // would otherwise toggle against a stale cached box.
  await LocalStore.reloadHabits();

  final habitId = uri.queryParameters['habitId'];
  final dayIndex = int.tryParse(uri.queryParameters['dayIndex'] ?? '');
  if (habitId == null || dayIndex == null) return;

  final habits = LocalStore.readHabits();
  final habit = habits[habitId];
  if (habit == null) return;

  final target =
      DateTime.now().subtract(Duration(days: 6 - dayIndex)).atMidnight;
  final completions = {...habit.completions};
  if (habit.isCompletedOn(target)) {
    completions.remove(target.dayKey);
  } else {
    completions[target.dayKey] =
        Completion(date: target.dayKey, hour: DateTime.now().hour);
  }

  final updated = habit.copyWith(completions: completions);
  habits[habitId] = updated;
  await LocalStore.writeHabit(updated);
  await HomeWidgetService.sync(habits);
}
