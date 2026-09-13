import 'dart:convert';

import 'package:flutter/material.dart';

enum TodoTagKind { project, label }

class TodoTag {
  const TodoTag({
    required this.id,
    required this.name,
    required this.color,
    this.icon = 'folder',
    this.order = 0,
    this.kind = TodoTagKind.label,
  });

  final String id;
  final String name;
  final Color color;
  final String icon;
  final int order;
  final TodoTagKind kind;

  bool get isProject => kind == TodoTagKind.project;

  TodoTag copyWith({
    String? name,
    Color? color,
    String? icon,
    int? order,
    TodoTagKind? kind,
  }) =>
      TodoTag(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        order: order ?? this.order,
        kind: kind ?? this.kind,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'icon': icon,
        'order': order,
        'kind': kind.name,
      };

  factory TodoTag.fromMap(Map<String, dynamic> map) => TodoTag(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        color: Color((map['color'] ?? 0xFF7C5CFC) as int),
        icon: (map['icon'] ?? 'folder') as String,
        order: ((map['order'] ?? 0) as num).toInt(),
        kind: TodoTagKind.values.firstWhere(
          (k) => k.name == map['kind'],
          orElse: () => TodoTagKind.label,
        ),
      );

  String toJson() => json.encode(toMap());

  factory TodoTag.fromJson(String source) =>
      TodoTag.fromMap(json.decode(source) as Map<String, dynamic>);
}

const todoTagPalette = [
  Color(0xFF7C5CFC),
  Color(0xFF34C759),
  Color(0xFFFF9500),
  Color(0xFFFF3B30),
  Color(0xFF5AC8FA),
  Color(0xFFFFCC00),
  Color(0xFFFF2D95),
  Color(0xFF00C8A0),
  Color(0xFF8E8E93),
];
