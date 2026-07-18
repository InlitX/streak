import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/app_strings.dart';
import 'package:streak/core/utils/cover_storage.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/water_cup.dart';

class QuantitativeProgress extends StatelessWidget {
  const QuantitativeProgress({super.key, required this.habit});

  final Habit habit;

  Future<void> _editAmount(BuildContext context, int current) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _AmountEditDialog(current: current, unit: habit.unitLabel),
    );
    if (result != null && result >= 0 && result != current && context.mounted) {
      context.read<HabitsController>().setProgress(habit.id, DateTime.now(), result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final count = habit.completions[today.dayKey]?.count ?? 0;
    final ratio =
        habit.perDayTarget <= 0 ? 0.0 : (count / habit.perDayTarget).clamp(0.0, 1.0);
    final controller = context.read<HabitsController>();

    void add(int delta) {
      HapticFeedback.mediumImpact();
      controller.addProgress(habit.id, today, delta);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            switch (habit.quantKind) {
              QuantKind.water => _WaterCups(count: count, target: habit.perDayTarget),
              QuantKind.reading =>
                _ReadingBooks(habit: habit, ratio: ratio, count: count),
              QuantKind.generic => _GenericRing(ratio: ratio, color: habit.color),
            },
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => _editAmount(context, count),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count / ${habit.perDayTarget} ${habit.unitLabel}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.pencil,
                        size: 14, color: context.tokens.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              context.tr('quant_daily_goal'),
              style: TextStyle(fontSize: 13, color: context.tokens.muted),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundActionButton(
                  icon: LucideIcons.minus,
                  color: habit.color,
                  onTap: count > 0 ? () => add(-habit.incrementAmount) : null,
                ),
                const SizedBox(width: 20),
                _RoundActionButton(
                  icon: LucideIcons.plus,
                  color: habit.color,
                  filled: true,
                  onTap: () => add(habit.incrementAmount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountEditDialog extends StatefulWidget {
  const _AmountEditDialog({required this.current, required this.unit});

  final int current;
  final String unit;

  @override
  State<_AmountEditDialog> createState() => _AmountEditDialogState();
}

class _AmountEditDialogState extends State<_AmountEditDialog> {
  // Stateful so the controller is disposed after the route's exit animation.
  late final TextEditingController _input =
      TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('quant_edit_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _input,
              keyboardType: TextInputType.number,
              hint: widget.unit,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('cancel'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: scheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop(int.tryParse(_input.text) ?? widget.current),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('save'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled
              ? color.withValues(alpha: 0.08)
              : filled
                  ? color
                  : color.withValues(alpha: 0.14),
        ),
        child: Icon(
          icon,
          size: 22,
          color: disabled
              ? color.withValues(alpha: 0.3)
              : filled
                  ? Colors.white
                  : color,
        ),
      ),
    );
  }
}

class _WaterCups extends StatelessWidget {
  const _WaterCups({required this.count, required this.target});

  final int count;
  final int target;

  static const cupCount = 10;
  static const _firstRow = 6;

  @override
  Widget build(BuildContext context) {
    // Guard target <= 0 and non-finite before the clamp.
    final perCup = target <= 0 ? 1.0 : target / cupCount;
    var progress = perCup <= 0 ? 0.0 : count / perCup;
    if (!progress.isFinite) progress = 0.0;

    Widget glass(int i) {
      final fill = (progress - i).clamp(0.0, 1.0);
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fill),
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: 33,
          height: 48,
          child: CustomPaint(painter: WaterCupPainter(fill: t)),
        ),
      );
    }

    Widget row(int start, int end) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = start; i < end; i++) ...[
              if (i > start) const SizedBox(width: 12),
              glass(i),
            ],
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, _firstRow),
        const SizedBox(height: 14),
        row(_firstRow, cupCount),
      ],
    );
  }
}

class _ReadingBooks extends StatelessWidget {
  const _ReadingBooks({
    required this.habit,
    required this.ratio,
    required this.count,
  });

  final Habit habit;
  final double ratio;
  final int count;

  Future<void> _editCover(BuildContext context) async {
    final controller = context.read<HabitsController>();
    final path = await CoverStorage.pick();
    if (path != null) {
      controller.update(habit.copyWith(bookCoverPath: path));
    }
  }

  Widget _leaning(double angle, Alignment anchor, Widget child) => Transform(
        alignment: anchor,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(angle),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _leaning(
          0.22,
          Alignment.centerRight,
          _Book.reference(habit: habit, onEditCover: () => _editCover(context)),
        ),
        const SizedBox(width: 20),
        _leaning(
          -0.22,
          Alignment.centerLeft,
          _Book.progress(habit: habit, ratio: ratio, count: count),
        ),
      ],
    );
  }
}

class _Book extends StatelessWidget {
  const _Book.reference({required this.habit, required this.onEditCover})
      : ratio = 0,
        count = 0,
        isProgress = false;

  const _Book.progress({
    required this.habit,
    required this.ratio,
    required this.count,
  })  : onEditCover = null,
        isProgress = true;

  final Habit habit;
  final double ratio;
  final int count;
  final bool isProgress;
  final VoidCallback? onEditCover;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(10),
  );

  bool get _hasPhoto =>
      habit.bookCoverPath.isNotEmpty && File(habit.bookCoverPath).existsSync();

  @override
  Widget build(BuildContext context) {
    final done = isProgress && ratio >= 1.0;
    return GestureDetector(
      onTap: onEditCover,
      child: SizedBox(
        width: 96,
        height: 138,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 9,
              right: 3,
              bottom: 0,
              height: 10,
              child: CustomPaint(painter: _GroundShadowPainter()),
            ),
            Positioned(left: 0, right: 0, top: 0, bottom: 7, child: _body()),
            if (done)
              Positioned(
                right: -2,
                bottom: 12,
                child: _CheckSeal(color: habit.color),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return Stack(
      children: [
        Positioned(
          right: 0,
          top: 5,
          bottom: 5,
          width: 10,
          child: CustomPaint(painter: _PageEdgesPainter()),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 6,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: _radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isProgress)
                  _ProgressCover(color: habit.color, ratio: ratio, count: count)
                else if (_hasPhoto)
                  Image.file(File(habit.bookCoverPath), fit: BoxFit.cover)
                else
                  _JacketCover(color: habit.color, title: habit.name),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 9.5,
                  top: 5,
                  bottom: 5,
                  width: 1,
                  child:
                      ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
                ),
                if (onEditCover != null)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 12,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JacketCover extends StatelessWidget {
  const _JacketCover({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.10)!,
            color,
            Color.lerp(color, Colors.black, 0.14)!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCover extends StatelessWidget {
  const _ProgressCover({
    required this.color,
    required this.ratio,
    required this.count,
  });

  final Color color;
  final double ratio;
  final int count;

  Widget _count(Color c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
        child: Align(
          alignment: const Alignment(0, -0.12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 46,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0.5,
                color: c,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pale = Color.lerp(color, Colors.white, 0.82)!;
    final ink = Color.lerp(color, Colors.black, 0.38)!;
    final hi = Color.lerp(color, Colors.white, 0.42)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: pale),
          if (t > 0)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: t,
                widthFactor: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: color),
                    Align(
                      alignment: const Alignment(-0.55, 0),
                      child: FractionallySizedBox(
                        heightFactor: 0.92,
                        child: Container(
                          width: 9,
                          decoration: BoxDecoration(
                            color: hi.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 1,
                            color: hi.withValues(alpha: 0.75),
                          ),
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  hi.withValues(alpha: 0.28),
                                  color.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _count(ink),
          if (t > 0)
            ClipRect(
              clipper: _BottomFractionClipper(t),
              child: _count(Colors.white),
            ),
        ],
      ),
    );
  }
}

class _BottomFractionClipper extends CustomClipper<Rect> {
  _BottomFractionClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * (1 - fraction), size.width, size.height);

  @override
  bool shouldReclip(covariant _BottomFractionClipper old) =>
      old.fraction != fraction;
}

class _CheckSeal extends StatelessWidget {
  const _CheckSeal({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(LucideIcons.check, size: 16, color: color),
      ),
    );
  }
}

class _PageEdgesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final block = Path()
      ..moveTo(0, 1)
      ..lineTo(w - 2.5, 3)
      ..quadraticBezierTo(w, h / 2, w - 2.5, h - 3)
      ..lineTo(0, h - 1)
      ..close();

    canvas.drawPath(
      block,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE3DBC8), Color(0xFFF7F2E7), Color(0xFFEBE4D3)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.save();
    canvas.clipPath(block);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, h),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PageEdgesPainter old) => false;
}

class _GroundShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Offset.zero & size,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _GroundShadowPainter old) => false;
}

class _GenericRing extends StatelessWidget {
  const _GenericRing({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: 138,
          height: 138,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(138, 138),
                painter: _RingPainter(ratio: t, color: color),
              ),
              if (t >= 1.0)
                _CheckSeal(color: color)
              else
                Text(
                  '${(t * 100).round()}%',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  static const _stroke = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _stroke) / 2;
    final arc = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = color.withValues(alpha: 0.13),
    );

    if (ratio <= 0) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * ratio;
    final light = Color.lerp(color, Colors.white, 0.35)!;
    canvas.drawArc(
      arc,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + 2 * math.pi,
          colors: [light, color, light],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(start),
        ).createShader(arc),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio || old.color != color;
}
