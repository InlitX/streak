import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';

const focusPresets = [25, 45];
const focusBreakPresets = [5, 15];

class FocusDurationChips extends StatelessWidget {
  const FocusDurationChips({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.allowFlow = true,
  });

  final int minutes;
  final ValueChanged<int> onChanged;
  final bool allowFlow;

  Future<void> _pickCustom(BuildContext context) async {
    final value = await showNumberKeypadDialog(
      context,
      title: context.l10n.focus_duration,
      value: minutes < 1 ? 25 : minutes.toDouble(),
      unit: context.l10n.unit_min_short,
      min: 1,
    );
    if (value != null) onChanged(value.round().clamp(1, 600));
  }

  @override
  Widget build(BuildContext context) {
    final flow = minutes <= 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in focusPresets)
          _DurationChip(
            label: context.l10n.minutes_short('$preset'),
            selected: minutes == preset,
            onTap: () => onChanged(preset),
          ),
        if (!flow && !focusPresets.contains(minutes))
          _DurationChip(
            label: context.l10n.minutes_short('$minutes'),
            selected: true,
            onTap: () => _pickCustom(context),
          ),
        _PencilButton(onTap: () => _pickCustom(context)),
        if (allowFlow)
          _DurationChip(
            label: context.l10n.focus_flowtime,
            selected: flow,
            icon: LucideIcons.infinity,
            onTap: () => onChanged(0),
          ),
      ],
    );
  }
}

class FocusPomodoroCard extends StatelessWidget {
  const FocusPomodoroCard({
    super.key,
    required this.enabled,
    required this.breakMinutes,
    required this.onToggle,
    required this.onBreakChanged,
  });

  final bool enabled;
  final int breakMinutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onBreakChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.focus_pomodoro,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.focus_pomodoro_sub,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.focus_break,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.tokens.muted,
                      ),
                    ),
                  ),
                  for (final value in focusBreakPresets) ...[
                    const SizedBox(width: 8),
                    _DurationChip(
                      label: context.l10n.minutes_short('$value'),
                      selected: breakMinutes == value,
                      onTap: () => onBreakChanged(value),
                    ),
                  ],
                  if (!focusBreakPresets.contains(breakMinutes)) ...[
                    const SizedBox(width: 8),
                    _DurationChip(
                      label: context.l10n.minutes_short('$breakMinutes'),
                      selected: true,
                      onTap: () {},
                    ),
                  ],
                  const SizedBox(width: 8),
                  _PencilButton(
                    onTap: () async {
                      final value = await showNumberKeypadDialog(
                        context,
                        title: context.l10n.focus_break,
                        value: breakMinutes.toDouble(),
                        unit: context.l10n.unit_min_short,
                        min: 1,
                      );
                      if (value != null) {
                        onBreakChanged(value.round().clamp(1, 120));
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? accent : context.tokens.muted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PencilButton extends StatelessWidget {
  const _PencilButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.edit,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 42,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.pencil,
            size: 16,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
