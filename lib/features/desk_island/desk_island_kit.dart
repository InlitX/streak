import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/desk_island/desk_island_host.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_habit_card.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

enum IslandTab { today, focus, tasks }

class IslandKit {
  const IslandKit._();

  static const tile = Color(0xFF141414);
  static const tileHover = Color(0xFF1D1D1D);
  static const muted = Color(0xFF9A9A9A);
  static const faint = Color(0xFF5C5C5C);
  static const line = Color(0x1AFFFFFF);
  static const rest = Color(0xFF4ADE80);
  static const fire = Color(0xFFFF9F43);
  static const stop = Color(0xFFFF6B6B);

  static const figures = [FontFeature.tabularFigures()];
}

List<Habit> islandFocusHabits(HabitsController habits) => focusOrder(habits.habits)
    .where((h) => h.kind != HabitKind.negative)
    .take(6)
    .toList();

int? parseClock(String raw) {
  final text = raw.trim().replaceAll(RegExp('[hH. ]'), ':');
  if (text.isEmpty) return null;
  final parts = text.split(':').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty || parts.length > 2) return null;
  int? hour;
  int? minute;
  if (parts.length == 2) {
    hour = int.tryParse(parts[0]);
    minute = int.tryParse(parts[1].length == 1 ? '${parts[1]}0' : parts[1]);
  } else {
    final digits = parts.single;
    if (digits.length <= 2) {
      hour = int.tryParse(digits);
      minute = 0;
    } else if (digits.length <= 4) {
      hour = int.tryParse(digits.substring(0, digits.length - 2));
      minute = int.tryParse(digits.substring(digits.length - 2));
    }
  }
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}

bool focusWaits(FocusController focus) =>
    focus.isActive && (focus.isAwaiting || focus.switchIn > 0 || focus.isFinished);

void openInApp(Widget page) {
  AppNavigator.push(page, fade: true);
  DeskIslandHost.showApp();
}

class IslandToday {
  const IslandToday({
    required this.key,
    required this.due,
    required this.done,
    required this.best,
  });

  final String key;
  final List<Habit> due;
  final int done;
  final int best;

  int get total => due.length;
  bool get perfect => total > 0 && done == total;
  double get ratio => total == 0 ? 0 : done / total;

  static IslandToday of(HabitsController habits) {
    final now = AppClock.now();
    final counted = habits.habits.where((h) => !h.tracking).toList();
    final due = counted
        .where((h) => !h.isPausedOn(now) && h.isScheduledOn(now))
        .toList();
    bool settled(Habit h) => h.isCompletedOn(now) || h.isCoveredOn(now);
    return IslandToday(
      key: now.dayKey,
      due: due,
      done: due.where(settled).length,
      best: counted.fold<int>(0, (a, h) => math.max(a, h.currentStreak)),
    );
  }
}

class IslandRing extends StatelessWidget {
  const IslandRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 18,
    this.stroke = 2.6,
    this.child,
  });

  final double? value;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(value: value, color: color, stroke: stroke),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color, required this.stroke});

  final double? value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    final v = value;
    if (v == null || v <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * v.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}

class IslandButton extends StatefulWidget {
  const IslandButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.color,
    this.compact = false,
    this.expand = false,
    this.tall = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final Color? color;
  final bool compact;
  final bool expand;
  final bool tall;

  @override
  State<IslandButton> createState() => _IslandButtonState();
}

class _IslandButtonState extends State<IslandButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final tint = widget.color;
    final Color fill;
    if (primary && tint != null) {
      fill = tint.withValues(alpha: _hover ? 0.95 : 0.82);
    } else if (primary) {
      fill = _hover ? const Color(0xFF383838) : const Color(0xFF2C2C2C);
    } else {
      fill = _hover ? const Color(0xFF262626) : const Color(0xFF1B1B1B);
    }
    final ink = primary || tint == null ? Colors.white : tint;
    final off = widget.onTap == null;
    final height = widget.compact ? 30.0 : widget.tall ? 44.0 : 38.0;
    return Semantics(
      button: true,
      enabled: !off,
      label: widget.label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: off ? 0.35 : 1,
        child: MouseRegion(
          cursor: off ? MouseCursor.defer : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() {
            _hover = false;
            _down = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _down ? 0.96 : 1,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: height,
                width: widget.expand ? double.infinity : null,
                padding: EdgeInsets.symmetric(horizontal: widget.compact ? 11 : 16),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: Row(
                  mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: widget.compact ? 14 : 16, color: ink),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.compact ? 12.5 : widget.tall ? 14.5 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IslandIconButton extends StatefulWidget {
  const IslandIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 32,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  State<IslandIconButton> createState() => _IslandIconButtonState();
}

class _IslandIconButtonState extends State<IslandIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: size,
            padding: EdgeInsets.symmetric(horizontal: (size - size * 0.5) / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              color: Colors.white.withValues(alpha: _hover ? 0.12 : 0.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: _hover
                      ? Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: Text(
                            widget.tooltip,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Icon(
                  widget.icon,
                  size: size * 0.5,
                  color: _hover ? Colors.white : Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IslandHover extends StatefulWidget {
  const IslandHover({
    super.key,
    required this.builder,
    this.onTap,
  });

  final Widget Function(BuildContext context, bool hover) builder;
  final VoidCallback? onTap;

  @override
  State<IslandHover> createState() => _IslandHoverState();
}

class _IslandHoverState extends State<IslandHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hover),
      ),
    );
  }
}

BoxDecoration islandTile(bool hover) => BoxDecoration(
      color: hover ? IslandKit.tileHover : IslandKit.tile,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: hover ? 0.08 : 0.04)),
    );

class IslandEnter extends StatelessWidget {
  const IslandEnter({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = 40.0 * index.clamp(0, 8);
    final total = 280 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total.round()),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
      ),
    );
  }
}

class IslandFade extends StatefulWidget {
  const IslandFade({super.key, required this.child, this.size = 22});

  final Widget child;
  final double size;

  @override
  State<IslandFade> createState() => _IslandFadeState();
}

class _IslandFadeState extends State<IslandFade> {
  final _scroll = _SoftScroll();
  double _top = 0;
  double _bottom = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _metrics(ScrollMetricsNotification note) {
    _read(note.metrics);
    return false;
  }

  bool _scrolled(ScrollUpdateNotification note) {
    _read(note.metrics);
    return false;
  }

  void _read(ScrollMetrics metrics) {
    final top = metrics.extentBefore.clamp(0.0, widget.size);
    final bottom = metrics.extentAfter.clamp(0.0, widget.size);
    if (top == _top && bottom == _bottom) return;
    setState(() {
      _top = top;
      _bottom = bottom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: _scrolled,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _metrics,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            final h = math.max(rect.height, 1.0);
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0, _top / h, 1 - _bottom / h, 1],
            ).createShader(rect);
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: PrimaryScrollController(
              controller: _scroll,
              child: RawScrollbar(
                controller: _scroll,
                thickness: 3,
                radius: const Radius.circular(2),
                thumbColor: Colors.white.withValues(alpha: 0.18),
                crossAxisMargin: 0,
                mainAxisMargin: 6,
                fadeDuration: const Duration(milliseconds: 250),
                timeToFade: const Duration(milliseconds: 700),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftScroll extends ScrollController {
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      _SoftPosition(
        physics: physics,
        context: context,
        oldPosition: oldPosition,
        initialPixels: initialScrollOffset,
      );
}

class _SoftPosition extends ScrollPositionWithSingleContext {
  _SoftPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
  });

  double _target = 0;
  int _ticket = 0;
  bool _moving = false;

  @override
  void pointerScroll(double delta) {
    if (delta == 0 || !hasContentDimensions) return;
    final from = _moving ? _target : pixels;
    _target = (from + delta * 0.45).clamp(minScrollExtent, maxScrollExtent);
    if (_target == pixels) return;
    final ticket = ++_ticket;
    _moving = true;
    animateTo(
      _target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    ).whenComplete(() {
      if (ticket == _ticket) _moving = false;
    });
  }
}
