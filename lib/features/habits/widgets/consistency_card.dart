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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.activity, size: 20, color: habit.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.consistency,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${habit.consistency}%',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: habit.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StrengthBar(
              value: habit.strength,
              color: habit.color,
              track: context.colors.surfaceContainerHighest,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.consistency_sub,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
