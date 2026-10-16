import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_tabs.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/focus/widgets/focus_setup_parts.dart';

class FocusDial extends StatelessWidget {
  const FocusDial({
    super.key,
    required this.mode,
    required this.minutes,
    required this.breakMinutes,
    required this.color,
    required this.size,
    required this.onMinutes,
    required this.onCustom,
  });

  final FocusMode mode;
  final int minutes;
  final int breakMinutes;
  final Color color;
  final double size;
  final ValueChanged<int> onMinutes;
  final VoidCallback onCustom;

  bool get _flow => mode == FocusMode.flow;

  double get _stroke => size * 0.055;

  bool _onRing(Offset local) {
    final distance = (local - Offset(size / 2, size / 2)).distance;
    final radius = (size - _stroke) / 2;
    return distance > radius * 0.62 && distance < radius * 1.3;
  }

  void _drag(Offset local) {
    final delta = local - Offset(size / 2, size / 2);
    var angle = math.atan2(delta.dx, -delta.dy);
    if (angle < 0) angle += 2 * math.pi;
    var picked =
        (angle / (2 * math.pi) * focusDialMax / focusDialStep).round() *
        focusDialStep;
    if (minutes >= focusDialMax - 20 && picked <= 20) picked = focusDialMax;
    if (minutes <= 20 && picked >= focusDialMax - 20) picked = focusDialStep;
    picked = picked.clamp(focusDialStep, focusDialMax);
    if (picked != minutes) onMinutes(picked);
  }

  String _endsAt(BuildContext context) {
    final end = DateTime.now().add(Duration(minutes: minutes));
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(end),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return context.l10n.focus_ends_at(time);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final caption = _flow
        ? context.l10n.focus_no_limit
        : mode == FocusMode.pomodoro
        ? '${context.l10n.focus_break} · ${context.l10n.minutes_short('$breakMinutes')}'
        : _endsAt(context);

    final center = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _flow ? null : onCustom,
      child: SizedBox.square(
        dimension: size * 0.66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FocusSwap(
              size: false,
              child: _flow
                  ? Icon(
                      LucideIcons.infinity,
                      key: const ValueKey('flow'),
                      size: size * 0.24,
                      color: context.colors.onSurface,
                    )
                  : FittedBox(
                      key: const ValueKey('time'),
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatDuration(minutes * 60),
                        maxLines: 1,
                        style: sheetFigureStyle(context, size: size * 0.2)
                            .copyWith(
                              height: 1,
                              letterSpacing: -1.2,
                              color: context.colors.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
            ),
            SizedBox(height: size * 0.035),
            FocusSwap(
              size: false,
              child: Text(
                caption,
                key: ValueKey(mode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sheetLabelStyle(context, size: 13, color: muted),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      slider: !_flow,
      label: context.l10n.focus_duration,
      value: _flow
          ? context.l10n.focus_flowtime
          : context.l10n.minutes_short('$minutes'),
      increasedValue: _flow
          ? null
          : context.l10n.minutes_short(
              '${(minutes + focusDialStep).clamp(focusDialStep, 600)}',
            ),
      decreasedValue: _flow
          ? null
          : context.l10n.minutes_short(
              '${(minutes - focusDialStep).clamp(focusDialStep, 600)}',
            ),
      onIncrease: _flow
          ? null
          : () =>
                onMinutes((minutes + focusDialStep).clamp(focusDialStep, 600)),
      onDecrease: _flow
          ? null
          : () =>
                onMinutes((minutes - focusDialStep).clamp(focusDialStep, 600)),
      child: RawGestureDetector(
        gestures: _flow
            ? const {}
            : {
                _RingDrag: GestureRecognizerFactoryWithHandlers<_RingDrag>(
                  () => _RingDrag(_onRing),
                  (drag) => drag
                    ..onStart = ((details) => _drag(details.localPosition))
                    ..onUpdate = ((details) => _drag(details.localPosition)),
                ),
              },
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: _flow ? 1 : minutes / focusDialMax),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, focusShare, _) => CustomPaint(
                  size: Size.square(size),
                  painter: _DialPainter(
                    focus: focusShare,
                    rest: mode == FocusMode.pomodoro
                        ? breakMinutes / focusDialMax
                        : 0,
                    flow: _flow,
                    color: color,
                    track: context.colors.onSurface.withValues(alpha: 0.08),
                    tick: context.colors.onSurface.withValues(alpha: 0.22),
                    knob: context.colors.surface,
                    stroke: _stroke,
                  ),
                ),
              ),
              center,
            ],
          ),
        ),
      ),
    );
  }
}

class _RingDrag extends PanGestureRecognizer {
  _RingDrag(this.accepts);

  final bool Function(Offset local) accepts;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      accepts(event.localPosition) && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolvePointer(event.pointer, GestureDisposition.accepted);
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.focus,
    required this.rest,
    required this.flow,
    required this.color,
    required this.track,
    required this.tick,
    required this.knob,
    required this.stroke,
  });

  final double focus;
  final double rest;
  final bool flow;
  final Color color;
  final Color track;
  final Color tick;
  final Color knob;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const top = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final inner = radius - stroke * 1.25;
    for (var i = 0; i < focusDialMax ~/ focusDialStep; i++) {
      final hour = i % 12 == 0;
      final angle = top + 2 * math.pi * i / (focusDialMax / focusDialStep);
      final length = hour ? stroke * 0.55 : stroke * 0.3;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * inner,
        center + direction * (inner - length),
        Paint()
          ..color = tick
          ..strokeWidth = hour ? 2 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    if (flow) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color.withValues(alpha: 0.35),
      );
      return;
    }

    final sweep = 2 * math.pi * focus.clamp(0.0, 1.0);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    if (rest > 0 && focus < 1) {
      final restSweep = 2 * math.pi * math.min(rest, 1 - focus);
      canvas.drawArc(
        rect,
        top + sweep,
        restSweep,
        false,
        arc..color = color.withValues(alpha: 0.3),
      );
    }

    canvas.drawArc(rect, top, sweep, false, arc..color = color);

    final head =
        center + Offset(math.cos(top + sweep), math.sin(top + sweep)) * radius;
    canvas.drawCircle(
      head,
      stroke * 1.05,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(head, stroke * 0.78, Paint()..color = color);
    canvas.drawCircle(head, stroke * 0.32, Paint()..color = knob);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.focus != focus ||
      old.rest != rest ||
      old.flow != flow ||
      old.color != color ||
      old.track != track;
}

class FocusModeSwitch extends StatelessWidget {
  const FocusModeSwitch({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final FocusMode mode;
  final ValueChanged<FocusMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.focus_mode_timer,
      context.l10n.focus_pomodoro,
      context.l10n.focus_flowtime,
    ];
    void pick(int i) => onChanged(FocusMode.values[i]);
    final style = context.watch<SettingsController>();
    if (style.isExpressStyle) {
      return ExpressTabs(labels: labels, index: mode.index, onChanged: pick);
    }
    if (style.isMinimalStyle) {
      return MinimalSegmented(
        options: labels,
        index: mode.index,
        onChanged: pick,
        expand: true,
      );
    }

    const icons = [LucideIcons.timer, LucideIcons.repeat, LucideIcons.infinity];
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: focusPanel(context).copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: mode.index == i,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pick(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: mode.index == i
                          ? scheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          size: 15,
                          color: mode.index == i
                              ? scheme.onPrimary
                              : context.tokens.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sheetActionStyle(
                              context,
                              size: 13.5,
                              color: mode.index == i
                                  ? scheme.onPrimary
                                  : context.tokens.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FocusOptionTag extends StatelessWidget {
  const FocusOptionTag({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final tone = on ? accent : context.tokens.muted;
    return Semantics(
      button: true,
      toggled: on,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(9, 6, 11, 6),
          decoration: BoxDecoration(
            color: on ? accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: on
                  ? accent
                  : context.colors.onSurface.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? LucideIcons.check : LucideIcons.plus,
                size: 13,
                color: tone,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: sheetLabelStyle(context, size: 12, color: tone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusChoiceRow extends StatelessWidget {
  const FocusChoiceRow({
    super.key,
    required this.presets,
    required this.value,
    required this.onPick,
    required this.onCustom,
    this.title,
  });

  final List<int> presets;
  final int value;
  final ValueChanged<int> onPick;
  final VoidCallback onCustom;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final custom = !presets.contains(value);
    return Row(
      children: [
        if (title != null) ...[
          Text(title!, style: sheetLabelStyle(context)),
          const SizedBox(width: 10),
        ],
        for (final preset in presets) ...[
          Expanded(
            child: _Choice(
              label: context.l10n.minutes_short('$preset'),
              selected: value == preset,
              onTap: () => onPick(preset),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _Choice(
            label: custom ? context.l10n.minutes_short('$value') : null,
            semantics: context.l10n.focus_custom_duration,
            selected: custom,
            onTap: onCustom,
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semantics,
  });

  final String? label;
  final bool selected;
  final VoidCallback onTap;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>();
    final minimal = style.isMinimalStyle;
    final accent = context.colors.primary;
    final idle = focusPanel(context);
    final fill = minimal
        ? context.colors.onSurface
        : accent.withValues(alpha: 0.16);
    final tone = selected
        ? (minimal ? context.colors.surface : accent)
        : context.colors.onSurface.withValues(alpha: 0.75);
    final radius = BorderRadius.circular(style.isExpressStyle ? 16 : 12);

    return Semantics(
      button: true,
      selected: selected,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? fill : idle.color,
            borderRadius: radius,
            border: Border.all(
              color: selected && !minimal ? accent : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: label == null
              ? Icon(LucideIcons.pencil, size: 15, color: tone)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      label!,
                      maxLines: 1,
                      style: sheetActionStyle(context, size: 14, color: tone),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
