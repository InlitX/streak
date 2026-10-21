import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/widgets/water_cup.dart';
import 'package:streak/services/health_steps.dart';

enum _Preset { water, reading, time, steps, generic }

class QuantPresetGrid extends StatefulWidget {
  const QuantPresetGrid({
    super.key,
    required this.quantKind,
    required this.steps,
    required this.color,
    required this.onSelected,
    required this.onSteps,
    this.plain = false,
  });

  final QuantKind quantKind;
  final bool steps;
  final Color color;
  final ValueChanged<QuantKind> onSelected;
  final VoidCallback onSteps;
  final bool plain;

  @override
  State<QuantPresetGrid> createState() => _QuantPresetGridState();
}

class _QuantPresetGridState extends State<QuantPresetGrid> {
  HealthAccess _access = HealthAccess.unsupported;

  @override
  void initState() {
    super.initState();
    HealthSteps.access().then((access) {
      if (mounted) setState(() => _access = access);
    });
  }

  _Preset get _current => switch (widget.quantKind) {
        QuantKind.water => _Preset.water,
        QuantKind.reading => _Preset.reading,
        QuantKind.time => _Preset.time,
        QuantKind.generic => widget.steps ? _Preset.steps : _Preset.generic,
      };

  Future<void> _pickSteps() async {
    if (await HealthSteps.request()) {
      if (mounted) setState(() => _access = HealthAccess.granted);
      widget.onSteps();
      return;
    }
    if (!mounted) return;
    AppSnackbar.action(
      context,
      context.l10n.health_steps_denied,
      label: context.l10n.health_permission,
      onPressed: HealthSteps.openSettings,
    );
  }

  void _pick(_Preset preset) => switch (preset) {
        _Preset.water => widget.onSelected(QuantKind.water),
        _Preset.reading => widget.onSelected(QuantKind.reading),
        _Preset.time => widget.onSelected(QuantKind.time),
        _Preset.steps => _pickSteps(),
        _Preset.generic => widget.onSelected(QuantKind.generic),
      };

  String _label(_Preset preset) => switch (preset) {
        _Preset.water => context.l10n.quant_preset_water,
        _Preset.reading => context.l10n.quant_preset_reading,
        _Preset.time => context.l10n.quant_preset_time,
        _Preset.steps => context.l10n.quant_preset_steps,
        _Preset.generic => context.l10n.quant_preset_generic,
      };

  String? _unit(_Preset preset) => switch (preset) {
        _Preset.water => context.l10n.quant_unit_ml,
        _Preset.reading => context.l10n.quant_unit_pages,
        _Preset.time => context.l10n.unit_min_short,
        _Preset.steps => context.l10n.health_unit_steps,
        _Preset.generic => null,
      };

  @override
  Widget build(BuildContext context) {
    final presets = [
      _Preset.water,
      _Preset.reading,
      _Preset.time,
      if (_access != HealthAccess.unsupported || widget.steps) _Preset.steps,
      _Preset.generic,
    ];
    final gap = widget.plain ? 7.0 : 8.0;
    Widget tile(_Preset preset) => _PresetTile(
          preset: preset,
          label: _label(preset),
          unit: _unit(preset),
          color: widget.color,
          selected: preset == _current,
          plain: widget.plain,
          onTap: () => _pick(preset),
        );
    return Column(
      children: [
        for (var i = 0; i < presets.length; i += 2) ...[
          if (i > 0) SizedBox(height: gap),
          if (i + 1 < presets.length)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(presets[i])),
                  SizedBox(width: gap),
                  Expanded(child: tile(presets[i + 1])),
                ],
              ),
            )
          else
            tile(presets[i]),
        ],
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.label,
    required this.unit,
    required this.color,
    required this.selected,
    required this.plain,
    required this.onTap,
  });

  final _Preset preset;
  final String label;
  final String? unit;
  final Color color;
  final bool selected;
  final bool plain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final weight = selected ? 700.0 : 600.0;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: plain ? 11 : 12,
            vertical: plain ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(plain ? 10 : 14),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.8) : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              if (!plain) ...[
                TweenAnimationBuilder<double>(
                  tween: Tween(end: selected ? 0.72 : 0.28),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) => _PresetArt(
                    preset: preset,
                    fill: t,
                    color: selected ? color : muted,
                  ),
                ),
                const SizedBox(width: 11),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: plain ? 12.5 : 13.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          fontVariations: [FontVariation('wght', weight)],
                          color: selected ? color : context.colors.onSurface,
                        ),
                      ),
                    ),
                    if (unit != null && !plain)
                      Text(
                        unit!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetArt extends StatelessWidget {
  const _PresetArt({
    required this.preset,
    required this.fill,
    required this.color,
  });

  final _Preset preset;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final art = switch (preset) {
      _Preset.water => CustomPaint(
          size: const Size(26, 34),
          painter: WaterCupPainter(fill: fill),
        ),
      _Preset.reading => CustomPaint(
          size: const Size(26, 33),
          painter: BookPainter(fill: fill, color: color),
        ),
      _Preset.time => CustomPaint(
          size: const Size(30, 34),
          painter: StopwatchPainter(fill: fill, color: color),
        ),
      _Preset.steps => CustomPaint(
          size: const Size(25, 34),
          painter: FootPainter(fill: fill, color: color),
        ),
      _Preset.generic => CustomPaint(
          size: const Size(32, 32),
          painter: DialPainter(fill: fill, color: color),
        ),
    };
    return SizedBox(width: 34, height: 36, child: Center(child: art));
  }
}
