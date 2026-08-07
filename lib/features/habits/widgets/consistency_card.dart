import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/strength_bar.dart';

class ConsistencyCard extends StatelessWidget {
  const ConsistencyCard({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(LucideIcons.activity, size: 20, color: habit.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.consistency,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.tokens.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${habit.consistency}%',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StrengthBar(
              value: habit.strength,
              color: habit.color,
              track: context.colors.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}
