import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Category {
  Category({
    required this.id,
    required this.name,
    required this.color,
    this.icon = 'folder',
  });

  final String id;
  final String name;
  final Color color;
  final String icon;

  Category copyWith({String? name, Color? color, String? icon}) => Category(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'icon': icon,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        color: Color(map['color'] as int),
        icon: (map['icon'] ?? 'folder') as String,
      );

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source) as Map<String, dynamic>);
}

class CategoryIcons {
  const CategoryIcons._();

  static const Map<String, IconData> all = {
    'folder': LucideIcons.folder,
    'star': LucideIcons.star,
    'bolt': LucideIcons.zap,
    'home': LucideIcons.house,
    'brain': LucideIcons.brain,
    'heart': LucideIcons.heart,
    'target': LucideIcons.target,
    'book': LucideIcons.book,
    'dumbbell': LucideIcons.dumbbell,
    'run': LucideIcons.footprints,
    'bike': LucideIcons.bike,
    'apple': LucideIcons.apple,
    'coffee': LucideIcons.coffee,
    'droplet': LucideIcons.droplet,
    'moon': LucideIcons.moon,
    'sun': LucideIcons.sun,
    'music': LucideIcons.music,
    'palette': LucideIcons.palette,
    'camera': LucideIcons.camera,
    'code': LucideIcons.code,
    'briefcase': LucideIcons.briefcase,
    'graduation': LucideIcons.graduationCap,
    'pencil': LucideIcons.pencil,
    'language': LucideIcons.languages,
    'wallet': LucideIcons.wallet,
    'leaf': LucideIcons.leaf,
    'flame': LucideIcons.flame,
    'sparkles': LucideIcons.sparkles,
    'smile': LucideIcons.smile,
    'gamepad': LucideIcons.gamepad2,
    'phone': LucideIcons.smartphone,
    'shopping': LucideIcons.shoppingBag,
    'plane': LucideIcons.plane,
    'dog': LucideIcons.dog,
    'pill': LucideIcons.pill,
    'bed': LucideIcons.bedDouble,
    'utensils': LucideIcons.utensils,
    'globe': LucideIcons.globe,
    'trophy': LucideIcons.trophy,
    'clock': LucideIcons.clock,
  };

  static List<String> get names => all.keys.toList();

  static IconData resolve(String name) => all[name] ?? all['folder']!;
}
