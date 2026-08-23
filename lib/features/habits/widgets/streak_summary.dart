import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class StreakSummary extends StatelessWidget {
  const StreakSummary({super.key, required this.habit});

  final Habit habit;

  String _format(BuildContext context, int value) => switch (habit.interval) {
        HabitInterval.weekly => context.l10n.count_weeks(value),
        HabitInterval.monthly => context.l10n.count_months(value),
        _ => context.l10n.count_days(value),
      };

  @override
  Widget build(BuildContext context) {
    final negative = habit.kind == HabitKind.negative;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: LucideIcons.flame,
            iconColor: habit.color,
            shape: ExpressShape.cookie,
            label: context.l10n.current,
            value: _format(context, habit.currentStreak),
          ),
        ),
        const SizedBox(width: Express.groupGap),
        Expanded(
          child: _StatBox(
            icon: LucideIcons.trophy,
            iconColor: context.tokens.warning,
            shape: ExpressShape.gem,
            label: context.l10n.best,
            value: _format(context, habit.longestStreak),
          ),
        ),
        const SizedBox(width: Express.groupGap),
        Expanded(
          child: _StatBox(
            icon: negative ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
            iconColor: negative ? context.tokens.danger : context.tokens.success,
            shape: ExpressShape.clover,
            label: negative ? context.l10n.relapses : context.l10n.total,
            value: '${habit.totalCompletions}',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.shape,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final ExpressShape shape;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    if (context.watch<SettingsController>().isExpressStyle) {
      return ExpressCard(
        radius: Express.cardRadius,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            ExpressBlob(
              size: 34,
              color: iconColor.withValues(alpha: 0.18),
              shape: shape,
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: ExpressType.display.at(
                  19,
                  height: 1,
                  spacing: -0.3,
                  color: scheme.onSurface,
                  tabular: true,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ExpressType.body.at(
                11,
                weight: 700,
                color: context.tokens.muted,
              ),
            ),
          ],
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}
