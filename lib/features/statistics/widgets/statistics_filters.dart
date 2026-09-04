import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/data/habit.dart';

class HabitFilter extends StatelessWidget {
  const HabitFilter({
    super.key,
    required this.habits,
    required this.selected,
    required this.onSelected,
  });

  final List<Habit> habits;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: context.l10n.all,
            color: context.colors.primary,
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final habit in habits)
            _FilterChip(
              label: habit.name,
              color: habit.color,
              active: selected == habit.id,
              onTap: () => onSelected(habit.id),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? color : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active
                    ? (color.computeLuminance() > 0.55
                        ? Colors.black
                        : Colors.white)
                    : context.tokens.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YearNavigator extends StatelessWidget {
  const YearNavigator({
    super.key,
    required this.year,
    required this.canGoForward,
    required this.onChanged,
  });

  final int year;
  final bool canGoForward;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ArrowButton(
          icon: LucideIcons.chevronLeft,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(-1);
          },
        ),
        SizedBox(
          width: 96,
          child: Text(
            '$year',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
        ),
        _ArrowButton(
          icon: LucideIcons.chevronRight,
          onTap: canGoForward
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(1);
                }
              : null,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 22,
        color: enabled
            ? context.colors.onSurface
            : context.tokens.muted.withValues(alpha: 0.4),
      ),
    );
  }
}

