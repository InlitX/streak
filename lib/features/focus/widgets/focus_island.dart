import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/app_dirs.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/services/focus_service.dart';

const _ink = Color(0xFF8E8E93);
const _track = Color(0xFF2C2C2E);
const _breakTint = Color(0xFFFFB340);
const _doneTint = Color(0xFF32D74B);
const _stopTint = Color(0xFFFF453A);
const _spring = SpringDescription(mass: 1, stiffness: 380, damping: 24);


class FocusIsland extends StatefulWidget {
  const FocusIsland({super.key, required this.child});

  static final pages = ValueNotifier<int>(0);

  final Widget child;

  @override
  State<FocusIsland> createState() => _FocusIslandState();
}

class _FocusIslandState extends State<FocusIsland>
    with TickerProviderStateMixin {
  late final FocusController _focus = context.read<FocusController>();
  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late final AnimationController _open = AnimationController.unbounded(
    vsync: this,
  );
  Timer? _settle;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_follow);
    FocusIsland.pages.addListener(_follow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
  }

  @override
  void dispose() {
    _focus.removeListener(_follow);
    FocusIsland.pages.removeListener(_follow);
    _settle?.cancel();
    _presence.dispose();
    _open.dispose();
    super.dispose();
  }

  void _follow() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
      return;
    }
    final shown = isMobile &&
        _focus.isActive &&
        FocusIsland.pages.value == 0 &&
        context.read<SettingsController>().focusEnabled;
    if (shown && _presence.status != AnimationStatus.forward &&
        _presence.value < 1) {
      _presence.forward();
    } else if (!shown && _presence.value > 0 &&
        _presence.status != AnimationStatus.reverse) {
      _fold();
      _presence.reverse();
    }
  }

  void _unfold() {
    setState(() => _expanded = true);
    _open.animateWith(SpringSimulation(_spring, _open.value, 1, 0));
    _restartSettle();
  }

  void _fold() {
    _settle?.cancel();
    if (!_expanded) return;
    setState(() => _expanded = false);
    _open.animateWith(SpringSimulation(_spring, _open.value, 0, 0));
  }

  void _restartSettle() {
    _settle?.cancel();
    _settle = Timer(const Duration(seconds: 6), _fold);
  }

  void _toggle() {
    if (_focus.isAwaiting) {
      _focus.continueNow();
    } else {
      _focus.isRunning ? _focus.pause() : _focus.resume();
    }
    _restartSettle();
  }

  void _end() {
    _fold();
    applyFocusAction(
      FocusAction(kind: FocusAction.stop, at: DateTime.now()),
    );
  }

  void _enter() {
    _fold();
    AppNavigator.push(
      const FocusPage(),
      fade: true,
      name: FocusPage.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isMobile) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: Listenable.merge([_presence, _open, _focus]),
          builder: (context, _) {
            if (_presence.value == 0) return const SizedBox.shrink();
            return _layer(context);
          },
        ),
      ],
    );
  }

  Widget _layer(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final source = islandSource(media);
    final compact = Rect.fromCenter(
      center: source.center,
      width: math.max(156, source.width + 128),
      height: source.height.clamp(30.0, 38.0) + 2,
    );
    final panelWidth = math.min(width - 20, 440.0);
    final expanded = Rect.fromLTWH(
      (width - panelWidth) / 2,
      math.max(6, compact.top - 2),
      panelWidth,
      150,
    );
    final open = _open.value;
    final grown = Curves.easeOutBack.transform(_presence.value);
    final settled = Rect.lerp(compact, expanded, open)!;
    final rect = Rect.lerp(source, settled, grown)!;
    final radius = ui.lerpDouble(
      source.shortestSide / 2,
      ui.lerpDouble(compact.height / 2, 46, open.clamp(0.0, 1.0))!,
      grown.clamp(0.0, 1.0),
    )!;
    final reveal = Curves.easeOut.transform(
      ((_presence.value - 0.35) / 0.65).clamp(0.0, 1.0),
    );

    final habits = context.watch<HabitsController>();
    final habit =
        _focus.habitId.isEmpty ? null : habits.byId(_focus.habitId);
    final accent = _accentOf(habit?.color ?? Theme.of(context).colorScheme.primary);
    final font = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return Positioned.fill(
      child: Stack(
        children: [
          if (_expanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _fold,
              ),
            ),
          Positioned.fromRect(
            rect: rect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _expanded ? _enter : _unfold,
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 120 && !_expanded) _unfold();
                if (velocity < -120 && _expanded) _fold();
              },
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: font,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
                child: _Shell(
                  radius: radius,
                  open: open,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (reveal * (1 - open * 2.4)).clamp(0.0, 1.0),
                        child: _Compact(
                          width: compact.width,
                          accent: accent,
                          progress: _focus.progress,
                          time: formatDuration(_focus.displaySeconds),
                        ),
                      ),
                      Opacity(
                        opacity: ((open - 0.4) / 0.6).clamp(0.0, 1.0),
                        child: OverflowBox(
                          minWidth: expanded.width,
                          maxWidth: expanded.width,
                          minHeight: expanded.height,
                          maxHeight: expanded.height,
                          child: _Panel(
                            focus: _focus,
                            title: habit?.name ?? context.l10n.focus,
                            accent: accent,
                            radius: 46,
                            onToggle: _toggle,
                            onEnd: _end,
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

  Color _accentOf(Color habit) {
    if (_focus.isAwaiting) return _doneTint;
    if (_focus.isBreak) return _breakTint;
    if (!_focus.isFlow && _focus.reachedTarget && !_focus.isPomodoro) {
      return _doneTint;
    }
    if (!_focus.isRunning) return _ink;
    final hsl = HSLColor.fromColor(habit);
    return hsl.withLightness(hsl.lightness.clamp(0.52, 0.72)).toColor();
  }
}

Rect islandSource(MediaQueryData media) {
  final width = media.size.width;
  final top = media.viewPadding.top;
  for (final feature in media.displayFeatures) {
    final bounds = feature.bounds;
    if (feature.type != ui.DisplayFeatureType.cutout) continue;
    if (bounds.top > top || bounds.width > width * 0.6 || bounds.isEmpty) {
      continue;
    }
    final side = math.max(bounds.height, 22.0);
    return Rect.fromCenter(
      center: bounds.center,
      width: math.max(bounds.width, side),
      height: side,
    );
  }
  final side = top > 30 ? 26.0 : 22.0;
  return Rect.fromCenter(
    center: Offset(width / 2, math.max(side / 2 + 6, top / 2)),
    width: side,
    height: side,
  );
}

class _Shell extends StatelessWidget {
  const _Shell({required this.radius, required this.open, required this.child});

  final double radius;
  final double open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lift = open.clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18 + 0.22 * lift),
            blurRadius: 10 + 26 * lift,
            offset: Offset(0, 4 + 10 * lift),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _Compact extends StatelessWidget {
  const _Compact({
    required this.width,
    required this.accent,
    required this.progress,
    required this.time,
  });

  final double width;
  final Color accent;
  final double progress;
  final String time;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      minWidth: width,
      maxWidth: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.8,
                strokeCap: StrokeCap.round,
                color: accent,
                backgroundColor: _track,
              ),
            ),
            const Spacer(),
            Text(
              time,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.focus,
    required this.title,
    required this.accent,
    required this.radius,
    required this.onToggle,
    required this.onEnd,
  });

  final FocusController focus;
  final String title;
  final Color accent;
  final double radius;
  final VoidCallback onToggle;
  final VoidCallback onEnd;

  String _headline(BuildContext context) {
    if (focus.isAwaiting) return context.l10n.focus_continue;
    if (!focus.isRunning) return context.l10n.focus_paused;
    if (focus.isFlow) return context.l10n.focus_flowtime;
    if (focus.reachedTarget && !focus.isPomodoro) {
      return context.l10n.focus_target_reached;
    }
    final end = DateTime.now().add(Duration(seconds: focus.remainingSeconds));
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(end),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarm = focus.isRunning &&
        !focus.isFlow &&
        !(focus.reachedTarget && !focus.isPomodoro);
    return CustomPaint(
      painter: _Rim(
        progress: focus.progress,
        color: accent,
        radius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Row(
          children: [
            _Round(
              fill: const Color(0xFF3A3A3C),
              icon: focus.isRunning && !focus.isAwaiting
                  ? LucideIcons.pause
                  : LucideIcons.play,
              color: Colors.white,
              label: focus.isRunning
                  ? context.l10n.focus_pause
                  : context.l10n.focus_resume,
              onTap: onToggle,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (alarm) ...[
                        const Icon(LucideIcons.bell, size: 14, color: _ink),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          _headline(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatDuration(focus.displaySeconds),
                      style: const TextStyle(
                        fontSize: 46,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    focus.isBreak ? context.l10n.focus_break : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
            _Round(
              fill: const Color(0xFF4A1512),
              icon: LucideIcons.x,
              color: _stopTint,
              label: context.l10n.focus_end,
              onTap: onEnd,
            ),
          ],
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.fill,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final Color fill;
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Icon(icon, size: 26, color: color),
        ),
      ),
    );
  }
}

class _Rim extends CustomPainter {
  const _Rim({required this.progress, required this.color, required this.radius});

  final double progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 7.0;
    const stroke = 5.0;
    final box = (Offset.zero & size).deflate(inset);
    final r = math.max(0.0, radius - inset);
    final path = Path()
      ..moveTo(box.center.dx, box.top)
      ..lineTo(box.right - r, box.top)
      ..arcToPoint(Offset(box.right, box.top + r), radius: Radius.circular(r))
      ..lineTo(box.right, box.bottom - r)
      ..arcToPoint(Offset(box.right - r, box.bottom),
          radius: Radius.circular(r))
      ..lineTo(box.left + r, box.bottom)
      ..arcToPoint(Offset(box.left, box.bottom - r),
          radius: Radius.circular(r))
      ..lineTo(box.left, box.top + r)
      ..arcToPoint(Offset(box.left + r, box.top), radius: Radius.circular(r))
      ..close();
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, pen..color = _track);
    final metric = path.computeMetrics().first;
    final done = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    canvas.drawPath(done, pen..color = color);
  }

  @override
  bool shouldRepaint(_Rim old) =>
      old.progress != progress || old.color != color || old.radius != radius;
}
