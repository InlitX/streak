import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class HabitDonut extends StatefulWidget {
  const HabitDonut({super.key, required this.entries, this.height = 215});

  final List<({String name, Color color, int count})> entries;
  final double height;

  @override
  State<HabitDonut> createState() => _HabitDonutState();
}

class _HabitDonutState extends State<HabitDonut> with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final AnimationController _select = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  int? _selected;
  List<double> _from = const [];
  List<double> _to = const [];

  @override
  void didUpdateWidget(HabitDonut old) {
    super.didUpdateWidget(old);
    if (old.entries.length != widget.entries.length) {
      _selected = null;
      _from = const [];
      _to = const [];
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _select.dispose();
    super.dispose();
  }

  double _at(List<double> values, int i) => i < values.length ? values[i] : 0;

  List<double> get _expansion => [
        for (var i = 0; i < widget.entries.length; i++)
          _at(_from, i) + (_at(_to, i) - _at(_from, i)) * _select.value,
      ];

  void _tap(int? index) {
    if (index == _selected) return;
    HapticFeedback.selectionClick();
    setState(() {
      _from = _expansion;
      _to = [
        for (var i = 0; i < widget.entries.length; i++) i == index ? 1.0 : 0.0,
      ];
      _selected = index;
    });
    _select.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final total = entries.fold<int>(0, (a, e) => a + e.count);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _DonutLayout(constraints.biggest, entries);
              return AnimatedBuilder(
                animation: Listenable.merge([_reveal, _select]),
                builder: (context, _) {
                  final active = _selected == null ? null : entries[_selected!];
                  return Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) =>
                          _tap(layout.hit(details.localPosition)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DonutPainter(
                                layout: layout,
                                reveal: _reveal.value,
                                expansion: _expansion,
                                total: total,
                                name: context.colors.onSurface,
                                muted: context.tokens.muted,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: layout.inner * 1.7,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 18),
                                AnimatedStatNumber(
                                  value: '${active?.count ?? total}',
                                  style: statNumber(context, 30),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  height: 13,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      active == null
                                          ? ''
                                          : '${(active.count * 100 / total).round()}%',
                                      key: ValueKey(active?.name ?? ''),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: statLabel(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _select,
          builder: (context, _) => Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < entries.length; i++)
                _LegendChip(
                  entry: entries[i],
                  percent: (entries[i].count * 100 / total).round(),
                  selected: i == _selected,
                  dimmed: _selected != null && i != _selected,
                  onTap: () => _tap(i == _selected ? null : i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.entry,
    required this.percent,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final ({String name, Color color, int count}) entry;
  final int percent;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: dimmed ? 0.4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: selected ? 0.16 : 0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: entry.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? context.colors.onSurface
                          : context.tokens.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text('$percent%', style: statNumber(context, 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const double _labelMinWidth = 56;

const double _labelEdge = 10;

const double _leaderStub = 14;

const double _leaderRun = 16;

class _Slice {
  const _Slice({required this.entry, required this.start, required this.sweep});

  final ({String name, Color color, int count}) entry;
  final double start;
  final double sweep;

  double get mid => start + sweep / 2;
  bool get onRight => math.cos(mid) >= 0;
}

class _DonutLayout {
  factory _DonutLayout(
    Size size,
    List<({String name, Color color, int count})> entries,
  ) {
    final outer = math.min(size.height * 0.46, size.width * 0.235);
    final total = entries.fold<int>(0, (a, e) => a + e.count);

    final slices = <_Slice>[];
    var angle = -math.pi / 2;
    for (final entry in entries) {
      final sweep = total == 0 ? 0.0 : 2 * math.pi * entry.count / total;
      slices.add(_Slice(entry: entry, start: angle, sweep: sweep));
      angle += sweep;
    }

    return _DonutLayout._(
      centre: Offset(size.width / 2, size.height / 2),
      outer: outer,
      thickness: outer * 0.30,
      slices: slices,
      size: size,
    );
  }

  const _DonutLayout._({
    required this.centre,
    required this.outer,
    required this.thickness,
    required this.slices,
    required this.size,
  });

  final Offset centre;
  final double outer;
  final double thickness;
  final List<_Slice> slices;
  final Size size;

  double get inner => outer - thickness;

  double turnX(bool onRight, double kneeX) => onRight
      ? math.max(size.width - _labelMinWidth - _labelEdge * 2, kneeX + _leaderRun)
      : math.min(_labelMinWidth + _labelEdge * 2, kneeX - _leaderRun);

  double labelWidth(bool onRight, double turn) => math.max(
        onRight ? size.width - turn - _labelEdge * 2 : turn - _labelEdge * 2,
        40,
      );

  int? hit(Offset point) {
    final vector = point - centre;
    final distance = vector.distance;
    if (distance < inner - 8 || distance > outer + 10) return null;
    var angle = math.atan2(vector.dy, vector.dx);
    while (angle < -math.pi / 2) {
      angle += 2 * math.pi;
    }
    while (angle >= 3 * math.pi / 2) {
      angle -= 2 * math.pi;
    }
    for (var i = 0; i < slices.length; i++) {
      if (angle >= slices[i].start &&
          angle < slices[i].start + slices[i].sweep) {
        return i;
      }
    }
    return null;
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.layout,
    required this.reveal,
    required this.expansion,
    required this.total,
    required this.name,
    required this.muted,
  });

  final _DonutLayout layout;
  final double reveal;
  final List<double> expansion;
  final int total;
  final Color name;
  final Color muted;

  double _grown(int i) => i < expansion.length ? expansion[i] : 0;

  @override
  void paint(Canvas canvas, Size size) {
    final swept =
        Curves.easeOutCubic.transform(reveal.clamp(0.0, 1.0)) * 2 * math.pi;
    final focus = expansion.isEmpty ? 0.0 : expansion.reduce(math.max);

    for (var i = 0; i < layout.slices.length; i++) {
      final slice = layout.slices[i];
      final grown = _grown(i);
      final drawn =
          (swept - (slice.start + math.pi / 2)).clamp(0.0, slice.sweep);
      if (drawn <= 0) continue;

      final radius = layout.outer - layout.thickness / 2 + grown * 6;
      final stroke = layout.thickness * (1 + grown * 0.18);

      final trim = math.min(stroke / 2 / radius + 0.012, slice.sweep / 2.4);
      canvas.drawArc(
        Rect.fromCircle(center: layout.centre, radius: radius),
        slice.start + trim,
        math.max(drawn - trim * 2, 0.0001),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color =
              slice.entry.color.withValues(alpha: 1 - (focus - grown) * 0.72),
      );
    }

    for (var i = 0; i < layout.slices.length; i++) {
      final grown = _grown(i);
      if (grown > 0.01) _callout(canvas, size, i, grown);
    }
  }

  void _callout(Canvas canvas, Size size, int index, double grown) {
    final slice = layout.slices[index];
    final direction = Offset(math.cos(slice.mid), math.sin(slice.mid));
    final start = layout.centre + direction * (layout.outer + 4 + grown * 6);
    final knee =
        layout.centre + direction * (layout.outer + _leaderStub + grown * 6);

    final turnX = layout.turnX(slice.onRight, knee.dx);
    final width = layout.labelWidth(slice.onRight, turnX);

    final text = math.max(0.0, (grown - 0.45) / 0.55);
    final labelText = _painter(
      slice.entry.name,
      TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: name.withValues(alpha: text),
      ),
      width,
      maxLines: 2,
    );
    final subText = _painter(
      '${slice.entry.count} · ${(slice.entry.count * 100 / total).round()}%',
      TextStyle(
        fontFamily: 'Figtree',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: muted.withValues(alpha: text),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      width,
    );

    final blockHeight = labelText.height + 3 + subText.height;
    final centreY = knee.dy.clamp(
      blockHeight / 2 + 2,
      size.height - blockHeight / 2 - 2,
    );
    final endX = knee.dx + (turnX - knee.dx) * grown;

    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(endX, centreY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.miter
        ..color = slice.entry.color.withValues(alpha: grown * 0.85),
    );
    canvas.drawCircle(
      start,
      3,
      Paint()..color = slice.entry.color.withValues(alpha: grown),
    );

    if (text <= 0) return;
    final left =
        slice.onRight ? turnX + _labelEdge : turnX - _labelEdge - width;
    final top = centreY - blockHeight / 2;
    final drift = (1 - text) * 6 * (slice.onRight ? 1 : -1);
    _write(canvas, labelText, left, top, drift, slice.onRight, width);
    _write(canvas, subText, left, top + labelText.height + 3, drift,
        slice.onRight, width);
  }

  TextPainter _painter(String text, TextStyle style, double width,
          {int maxLines = 1}) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: ui.TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: '…',
      )..layout(maxWidth: width);

  void _write(
    Canvas canvas,
    TextPainter painter,
    double left,
    double top,
    double drift,
    bool onRight,
    double width,
  ) {
    painter.paint(
      canvas,
      Offset(
        (onRight ? left : left + width - painter.width) + drift,
        top,
      ),
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.reveal != reveal ||
      !listEquals(old.expansion, expansion) ||
      old.total != total ||
      old.name != name;
}
