import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:streak/features/habits/data/habit.dart';

class LocalStore {
  const LocalStore._();

  static const _habitsBox = 'habits';
  static const _settingsBox = 'settings';
  static const _categoriesBox = 'categories';

  static late Box _habits;
  static late Box _settings;
  static late Box _categories;

  static Future<void> init() async {
    await Hive.initFlutter();
    _habits = await Hive.openBox(_habitsBox);
    _settings = await Hive.openBox(_settingsBox);
    _categories = await Hive.openBox(_categoriesBox);
  }

  static Map<String, Habit> readHabits() {
    final result = <String, Habit>{};
    for (final raw in _habits.values) {
      // Skip corrupt records so one bad entry can't block loading.
      try {
        final habit = Habit.fromJson(raw as String);
        result[habit.id] = habit;
      } catch (_) {}
    }
    return result;
  }

  static Future<void> writeHabit(Habit habit) =>
      _habits.put(habit.id, habit.toJson());

  static Future<void> removeHabit(String id) => _habits.delete(id);

  /// Closes and reopens the habits box so writes made by another isolate
  /// (e.g. the home-screen widget's background toggle) are picked up. Hive
  /// caches a box per isolate, so without reopening the foreground keeps a
  /// stale in-memory copy and never sees the widget's changes.
  static Future<void> reloadHabits() async {
    if (_habits.isOpen) await _habits.close();
    _habits = await Hive.openBox(_habitsBox);
  }

  static List<Category> readCategories() {
    final result = <Category>[];
    for (final raw in _categories.values) {
      try {
        result.add(Category.fromJson(raw as String));
      } catch (_) {}
    }
    return result;
  }

  static Future<void> writeCategory(Category category) =>
      _categories.put(category.id, category.toJson());

  static Future<void> removeCategory(String id) => _categories.delete(id);

  static bool get hasCategories => _categories.isNotEmpty;

  static T setting<T>(String key, T fallback) {
    // Fall back if the stored value's type no longer matches.
    final value = _settings.get(key, defaultValue: fallback);
    return value is T ? value : fallback;
  }

  static Future<void> writeSetting(String key, Object value) =>
      _settings.put(key, value);
}
