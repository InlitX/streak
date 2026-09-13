import 'package:flutter/material.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/features/todos/data/todo_tag.dart';
import 'package:uuid/uuid.dart';

class TodoTagsController extends ChangeNotifier {
  TodoTagsController() {
    _tags = LocalStore.readTodoTags();
  }

  final _uuid = const Uuid();
  late List<TodoTag> _tags;

  List<TodoTag> get tags =>
      [..._tags]..sort((a, b) => a.order.compareTo(b.order));

  List<TodoTag> get projects =>
      tags.where((t) => t.kind == TodoTagKind.project).toList();

  List<TodoTag> get labels =>
      tags.where((t) => t.kind == TodoTagKind.label).toList();

  bool get isEmpty => _tags.isEmpty;

  void reload() {
    _tags = LocalStore.readTodoTags();
    notifyListeners();
  }

  TodoTag? byId(String id) {
    for (final tag in _tags) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  List<TodoTag> resolve(Iterable<String> ids) => [
        for (final id in ids)
          if (byId(id) case final tag?) tag,
      ];

  Future<TodoTag> create({
    required String name,
    required Color color,
    required String icon,
    TodoTagKind kind = TodoTagKind.label,
  }) async {
    final tag = TodoTag(
      id: _uuid.v4(),
      name: name.trim(),
      color: color,
      icon: icon,
      order: _tags
              .where((t) => t.kind == kind)
              .fold<int>(-1, (top, t) => t.order > top ? t.order : top) +
          1,
      kind: kind,
    );
    _tags.add(tag);
    notifyListeners();
    await LocalStore.writeTodoTag(tag);
    return tag;
  }

  Future<void> update(TodoTag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index == -1) return;
    _tags[index] = tag;
    notifyListeners();
    await LocalStore.writeTodoTag(tag);
  }

  Future<void> remove(String id) async {
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
    await LocalStore.removeTodoTag(id);
  }

  Future<void> reorder(List<TodoTag> ordered) async {
    final renumbered = [
      for (final (index, tag) in ordered.indexed) tag.copyWith(order: index),
    ];
    final moved = {for (final tag in renumbered) tag.id};
    _tags = [..._tags.where((t) => !moved.contains(t.id)), ...renumbered];
    notifyListeners();
    for (final tag in renumbered) {
      await LocalStore.writeTodoTag(tag);
    }
  }
}
