import 'package:flutter/material.dart';

class DayStamp extends StatelessWidget {
  const DayStamp({
    super.key,
    required this.date,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final DateTime date;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.day}',
          maxLines: 1,
          style: TextStyle(
            fontSize: compact ? 13 : 14.5,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: compact ? 9.5 : 10.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
