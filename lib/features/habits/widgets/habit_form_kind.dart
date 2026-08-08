import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/hold_repeat_button.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/substep.dart';
import 'package:streak/features/habits/widgets/substep_draft.dart';

class KindSelector extends StatelessWidget {
  const KindSelector({
    super.key,
    required this.kind,
    required this.locked,
    required this.onChanged,
  });

  final HabitKind kind;
  final bool locked;
  final ValueChanged<HabitKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (HabitKind.positive, context.l10n.kind_positive, LucideIcons.circleCheck),
      (HabitKind.negative, context.l10n.kind_negative, LucideIcons.ban),
      (HabitKind.quantitative, context.l10n.kind_quantitative, LucideIcons.gauge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _KindOption(
                  active: options[i].$1 == kind,
                  dimmed: locked && options[i].$1 != kind,
                  label: options[i].$2,
                  icon: options[i].$3,
                  onTap: locked ? null : () => onChanged(options[i].$1),
                ),
              ),
            ],
          ],
        ),
        if (locked) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.lock, size: 13, color: context.tokens.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.kind_locked_hint,
                  style: TextStyle(fontSize: 12, color: context.tokens.muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.active,
    required this.dimmed,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final bool dimmed;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dimmed ? 0.35 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 20, color: active ? scheme.onPrimary : context.tokens.muted),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? scheme.onPrimary : context.tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NegativeHint extends StatelessWidget {
  const NegativeHint({
    super.key,required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.kind_negative_hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.tokens.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusOnlyToggle extends StatelessWidget {
  const FocusOnlyToggle({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
    this.compact = false,
  });

  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.timer, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.focus_only,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.focus_only_hint,
                  style: TextStyle(
                    fontSize: compact ? 11.5 : 12.5,
                    height: 1.35,
                    color: context.tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SubstepsEditor extends StatefulWidget {
  const SubstepsEditor({
    super.key,
    required this.substeps,
    required this.color,
    required this.onChanged,
  });

  final List<Substep> substeps;
  final Color color;
  final ValueChanged<List<Substep>> onChanged;

  @override
  State<SubstepsEditor> createState() => _SubstepsEditorState();
}

class _SubstepsEditorState extends State<SubstepsEditor> {
  late List<SubstepDraft> _steps;

  @override
  void initState() {
    super.initState();
    _steps = widget.substeps
        .map((s) => SubstepDraft(s.id, TextEditingController(text: s.title)))
        .toList();
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
        _steps
            .map((s) => Substep(id: s.id, title: s.controller.text.trim()))
            .toList(),
      );

  void _add() {
    setState(() {
      _steps.add(
        SubstepDraft(
          DateTime.now().microsecondsSinceEpoch.toString(),
          TextEditingController(),
        ),
      );
    });
    _emit();
  }

  void _remove(int index) {
    final removed = _steps[index];
    setState(() => _steps.removeAt(index));

    WidgetsBinding.instance
        .addPostFrameCallback((_) => removed.controller.dispose());
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.listChecks, size: 17, color: widget.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.checklist_hint,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.tokens.muted,
                    ),
                  ),
                ),
              ],
            ),
            if (_steps.isNotEmpty) const SizedBox(height: 14),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                key: ValueKey(_steps[i].id),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hint: context.l10n.step_hint,
                        controller: _steps[i].controller,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _remove(i),
                      icon: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: _add,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus, size: 18, color: widget.color),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.add_step,
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantitativeFields extends StatelessWidget {
  const QuantitativeFields({
    super.key,
    required this.quantKind,
    required this.unitController,
    required this.target,
    required this.increment,
    required this.onPresetSelected,
    required this.onUnitChanged,
    required this.onTargetChanged,
    required this.onIncrementChanged,
  });

  final QuantKind quantKind;
  final TextEditingController unitController;
  final double target;
  final double increment;
  final ValueChanged<QuantKind> onPresetSelected;
  final VoidCallback onUnitChanged;
  final ValueChanged<double> onTargetChanged;
  final ValueChanged<double> onIncrementChanged;

  double get _step => switch (quantKind) {
        QuantKind.water => 50,
        QuantKind.reading => 1,
        QuantKind.generic => 1,
      };

  @override
  Widget build(BuildContext context) {
    final unit = unitController.text.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _PresetChip(
                    icon: LucideIcons.droplet,
                    label: context.l10n.quant_preset_water,
                    selected: quantKind == QuantKind.water,
                    onTap: () => onPresetSelected(QuantKind.water),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PresetChip(
                    icon: LucideIcons.bookOpen,
                    label: context.l10n.quant_preset_reading,
                    selected: quantKind == QuantKind.reading,
                    onTap: () => onPresetSelected(QuantKind.reading),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PresetChip(
                    icon: LucideIcons.gauge,
                    label: context.l10n.quant_preset_generic,
                    selected: quantKind == QuantKind.generic,
                    onTap: () => onPresetSelected(QuantKind.generic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: context.l10n.quant_unit_hint,
              controller: unitController,
              onChanged: (_) => onUnitChanged(),
            ),
            const SizedBox(height: 12),
            _QuantityStepperRow(
              label: context.l10n.quant_daily_goal,
              value: target,
              unit: unit,
              step: _step,
              min: _step,
              onChanged: onTargetChanged,
            ),
            const SizedBox(height: 8),
            _QuantityStepperRow(
              label: context.l10n.quant_tap_amount,
              value: increment,
              unit: unit,
              step: _step,
              min: _step,
              onChanged: onIncrementChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.16)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: scheme.primary, width: 1.4) : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 17, color: selected ? scheme.primary : context.tokens.muted),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.primary : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepperRow extends StatelessWidget {
  const _QuantityStepperRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.step,
    required this.min,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String unit;
  final double step;
  final double min;
  final ValueChanged<double> onChanged;

  Future<void> _promptValue(BuildContext context) async {
    final result = await showNumberKeypadDialog(
      context,
      title: label,
      value: value,
      unit: unit,
      min: min,
      decimals: true,
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
          HoldRepeatButton(
            icon: LucideIcons.minus,
label: context.l10n.a11y_decrease,
            onTap: value > min ? () => onChanged(value - step) : null,
          ),
          Semantics(
            button: true,
            child: InkWell(
              onTap: () => _promptValue(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 60),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                alignment: Alignment.center,
                child: Text(
                  unit.isEmpty
                      ? formatAmount(value)
                      : '${formatAmount(value)} $unit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: scheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          HoldRepeatButton(
            icon: LucideIcons.plus,
label: context.l10n.a11y_increase,
            onTap: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}
