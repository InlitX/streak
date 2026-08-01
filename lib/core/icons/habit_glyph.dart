import 'package:flutter/material.dart';
import 'package:streak/core/icons/habit_icons.dart';

class HabitGlyph extends StatelessWidget {
  const HabitGlyph({
    super.key,
    required this.glyph,
    required this.size,
    this.color,
  });

  final String glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (HabitIcons.isIcon(glyph)) {
      return Icon(HabitIcons.resolve(glyph), size: size, color: color);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          glyph,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.8, height: 1.0),
        ),
      ),
    );
  }
}
