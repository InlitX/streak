import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/habits/data/category.dart';
import 'package:uuid/uuid.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController() {
    _categories = LocalStore.readCategories();
    _keepOwnNames();
    if (!LocalStore.hasCategories) {
      _seedDefaults();
    } else {
      unawaited(_dropDuplicates());
    }
  }

  Future<void> _dropDuplicates() async {
    final once = await LocalStore.readCategoriesOnce();
    if (once.length == _categories.length) return;
    _categories = once;
    notifyListeners();
  }

  static Set<String> ownNames = {};

  static bool isSeed(Category category) => category.id.startsWith('seed-');

  void _keepOwnNames() {
    ownNames = {
      for (final category in _categories)
        if (!isSeed(category)) category.name,
    };
  }

  @override
  void notifyListeners() {
    _keepOwnNames();
    super.notifyListeners();
  }

  static const seededNames = {
    'Health',
    'Fitness',
    'Mindfulness',
    'Productivity',
    'Learning',
    'Finance',
  };

  final _uuid = const Uuid();
  late List<Category> _categories;

  List<Category> get categories => [..._categories]
    ..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
    });

  void reload() {
    _categories = LocalStore.readCategories();
    if (!LocalStore.hasCategories) {
      _seedDefaults();
    } else {
      unawaited(_dropDuplicates());
    }
    notifyListeners();
  }

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
        id: 'seed-${name.toLowerCase()}',
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
    final key = LocalStore.categoryKey(name);
    for (final existing in _categories) {
      if (LocalStore.categoryKey(existing.name) == key) return existing;
    }
    final category = Category(
      id: _uuid.v4(),
      name: name,
      color: color,
      icon: icon,
      order: _categories.fold(0, (top, c) => c.order >= top ? c.order + 1 : top),
    );
    _categories.add(category);
    await LocalStore.writeCategory(category);
    notifyListeners();
    return category;
  }

  Future<void> reorder(List<Category> ordered) async {
    _categories = [
      for (final (index, category) in ordered.indexed)
        category.copyWith(order: index),
    ];
    notifyListeners();
    for (final category in _categories) {
      await LocalStore.writeCategory(category);
    }
  }

  Future<void> replace(Category before, Category after) async {
    final index = _categories.indexWhere((c) => c.id == before.id);
    if (index == -1) return;
    _categories[index] = after;
    if (before.id != after.id) await LocalStore.removeCategory(before.id);
    await LocalStore.writeCategory(after);
    notifyListeners();
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
