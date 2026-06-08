import 'package:flutter/material.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:uuid/uuid.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController() {
    _categories = LocalStore.readCategories();
    if (!LocalStore.hasCategories) _seedDefaults();
  }

  final _uuid = const Uuid();
  late List<Category> _categories;

  List<Category> get categories =>
      [..._categories]..sort((a, b) => a.name.compareTo(b.name));

  Category? byName(String name) {
    for (final c in _categories) {
      if (c.name == name) return c;
    }
    return null;
  }

  Future<void> _seedDefaults() async {
    const defaults = [
      ('Health', 0xFF34C759, 'heart'),
      ('Fitness', 0xFFFF9500, 'bolt'),
      ('Mindfulness', 0xFF5AC8FA, 'brain'),
      ('Productivity', 0xFFFFCC00, 'star'),
      ('Learning', 0xFF7C3AED, 'book'),
      ('Finance', 0xFF00C853, 'target'),
    ];
    for (final (name, color, icon) in defaults) {
      final category = Category(
        id: _uuid.v4(),
        name: name,
        color: Color(color),
        icon: icon,
      );
      _categories.add(category);
      await LocalStore.writeCategory(category);
    }
    notifyListeners();
  }

  Future<Category> create({
    required String name,
    required Color color,
    required String icon,
  }) async {
    final category = Category(
      id: _uuid.v4(),
      name: name,
      color: color,
      icon: icon,
    );
    _categories.add(category);
    await LocalStore.writeCategory(category);
    notifyListeners();
    return category;
  }

  Future<void> update(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index == -1) return;
    _categories[index] = category;
    await LocalStore.writeCategory(category);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await LocalStore.removeCategory(id);
    notifyListeners();
  }
}
