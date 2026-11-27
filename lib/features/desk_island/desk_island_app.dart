import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/app_lock.dart';
import 'package:streak/app/theme/app_theme.dart';
import 'package:streak/core/i18n/app_locale.dart';
import 'package:streak/core/shortcuts/app_shortcuts.dart';
import 'package:streak/features/desk_island/desk_island_card.dart';
import 'package:streak/features/desk_island/desk_island_host.dart';
import 'package:streak/features/desk_island/desk_island_kit.dart';
import 'package:streak/features/desk_island/desk_island_panel.dart';
import 'package:streak/features/desk_island/desk_island_pill.dart';
import 'package:streak/features/desk_island/desk_island_shape.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/l10n/app_localizations.dart';

class DeskIslandApp extends StatelessWidget {
  const DeskIslandApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = AppTheme.dark(
      settings.accentColor,
      settings.appStyle,
      settings.colorTheme,
    );
    return MaterialApp(
      title: 'Streak',
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      themeMode: ThemeMode.dark,
      locale: settings.locale,
      supportedLocales: shippedLocales,
      localeListResolutionCallback: (wanted, _) => pickLocale(wanted),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: settings.animations
              ? media
              : media.copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DeskIsland(),
    );
  }
}

enum _Mode { pill, card, open }

class DeskIsland extends StatefulWidget {
  const DeskIsland({super.key});

  @override
  State<DeskIsland> createState() => _DeskIslandState();
}

class _DeskIslandState extends State<DeskIsland> with TickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 380, damping: 29);

  late final AnimationController _morph = AnimationController.unbounded(
    vsync: this,
    value: 1,
  )..addListener(_sendShape);
  late IslandShape _from;
  late IslandShape _to;
  late final FocusController _focus;
  late final HabitsController _habits;
  _Mode _mode = _Mode.pill;
  IslandTab _tab = IslandTab.today;
  IslandCardData? _card;
  Timer? _hoverTimer;
  Timer? _cardTimer;
  Timer? _clock;
  bool _typing = false;
  bool _hovering = false;
  bool _started = false;
  bool _perfect = false;
  String _perfectDay = '';
  double _ratio = 1;
  Int32List? _sent;

  IslandShape get _shape => IslandShape.lerp(_from, _to, _morph.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ratio = MediaQuery.devicePixelRatioOf(context);
    if (!_started) {
      _started = true;
      _focus = context.read<FocusController>();
      _habits = context.read<HabitsController>();
      _from = _to = _target();
      _focus.completedTick.addListener(_focusEnded);
      _habits.addListener(_habitsChanged);
      DeskIslandHost.hidden.addListener(_hiddenChanged);
      DeskIslandHost.blurred.addListener(_stopTyping);
      AppLockGate.locked.addListener(_lockChanged);
      final today = IslandToday.of(_habits);
      _perfect = today.perfect;
      _perfectDay = today.key;
      _clock = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) setState(() {});
      });
    }
    _sent = null;
    _sendShape();
  }

  @override
  void dispose() {
    _focus.completedTick.removeListener(_focusEnded);
    _habits.removeListener(_habitsChanged);
    DeskIslandHost.hidden.removeListener(_hiddenChanged);
    DeskIslandHost.blurred.removeListener(_stopTyping);
    AppLockGate.locked.removeListener(_lockChanged);
    _hoverTimer?.cancel();
    _cardTimer?.cancel();
    _clock?.cancel();
    _morph.dispose();
    AppShortcuts.quiet = false;
    super.dispose();
  }

  bool get _locked => AppLockGate.locked.value;

  IslandShape _target() {
    final settings = context.read<SettingsController>();
    final focusing = settings.focusEnabled && _focus.isActive;
    final width = MediaQuery.sizeOf(context).width;
    IslandShape at(Size size, double radius) =>
        IslandShape.centered(size, radius, width: width);
    return switch (_mode) {
      _Mode.open => at(Size(_openWidth(), _openHeight()), 30),
      _Mode.card => at(const Size(452, 84), 28),
      _Mode.pill => _locked
          ? at(const Size(150, 32), 16)
          : focusing
          ? at(const Size(244, 36), 18)
          : at(
              Size(MediaQuery.alwaysUse24HourFormatOf(context) ? 212 : 236, 34),
              17,
            ),
    };
  }

  bool get _focusShown =>
      !_locked &&
      _tab == IslandTab.focus &&
      context.read<SettingsController>().focusEnabled &&
      _focus.isActive;

  double _openWidth() => _focusShown ? 480 : 608;

  double _openHeight() {
    const chrome = 10.0 + 40 + 12 + 18;
    double grid(int count) {
      final rows = (count + 1) ~/ 2;
      return rows == 0 ? 80 : rows * 58 + (rows - 1) * 8;
    }

    final settings = context.read<SettingsController>();
    final tab = switch (_tab) {
      IslandTab.focus when settings.focusEnabled => IslandTab.focus,
      IslandTab.tasks when settings.todosEnabled => IslandTab.tasks,
      _ => IslandTab.today,
    };
    final double body;
    if (_locked) {
      body = 150;
    } else if (tab == IslandTab.today) {
      body = 64 + 12 + grid(math.min(IslandToday.of(_habits).total, 6));
    } else if (tab == IslandTab.focus) {
      final count = islandFocusHabits(_habits).length;
      body = _focus.isActive
          ? 154
          : 64 + (count == 0 ? 0 : 12 + grid(math.min(count, 4)));
    } else {
      final sections = context.read<TodosController>().sections;
      final rows = sections.fold<int>(0, (sum, s) => sum + s.todos.length);
      body = 46 + 8 + 34 + 12 +
          (rows == 0 ? 80 : rows * 36 + sections.length * 28 - 12);
    }
    return (chrome + body).clamp(160.0, 404.0);
  }

  void _retarget() {
    if (!mounted) return;
    final target = _target();
    if (target.body == _to.body && target.radius == _to.radius) return;
    _from = _shape;
    _to = target;
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = 1;
      return;
    }
    _morph.value = 0;
    _morph.animateWith(SpringSimulation(_spring, 0, 1, 0));
  }

  void _sendShape() {
    final points = _shape.region(_ratio);
    final last = _sent;
    if (last != null && listEquals(last, points)) return;
    _sent = points;
    DeskIslandHost.shape(points);
  }

  void _setMode(_Mode mode) {
    if (!mounted || mode == _mode) return;
    if (mode != _Mode.open) _stopTyping();
    setState(() => _mode = mode);
  }

  void _enter() {
    _hoverTimer?.cancel();
    _hovering = true;
    if (_mode == _Mode.open) return;
    _hoverTimer = Timer(const Duration(milliseconds: 140), () {
      _setMode(_Mode.open);
    });
  }

  void _exit() {
    _hoverTimer?.cancel();
    _hovering = false;
    if (_typing) return;
    _hoverTimer = Timer(const Duration(milliseconds: 380), _fold);
  }

  void _fold() => _setMode(_card == null ? _Mode.pill : _Mode.card);

  void _typingChanged(bool typing) {
    if (typing == _typing) return;
    _typing = typing;
    AppShortcuts.quiet = typing;
    DeskIslandHost.keyboard(typing);
    if (typing || _hovering || _mode != _Mode.open) return;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 380), _fold);
  }

  void _stopTyping() {
    if (!_typing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _typingChanged(false);
  }

  void _hiddenChanged() {
    if (!DeskIslandHost.hidden.value) return;
    _hoverTimer?.cancel();
    _setMode(_card == null ? _Mode.pill : _Mode.card);
  }

  void _lockChanged() {
    if (!mounted) return;
    if (_locked) {
      _dropCard();
      _stopTyping();
    }
    setState(() {});
  }

  void _show(IslandCardData card, Duration stay) {
    if (_locked) return;
    _cardTimer?.cancel();
    setState(() {
      _card = card;
      if (_mode == _Mode.pill) _mode = _Mode.card;
    });
    _cardTimer = Timer(stay, _cardTimeout);
  }

  void _cardTimeout() {
    final card = _card;
    if (card == null) return;
    if (card.kind == IslandCardKind.focus && focusWaits(_focus)) {
      _cardTimer = Timer(const Duration(seconds: 2), _cardTimeout);
      return;
    }
    _dropCard();
  }

  void _dropCard() {
    _cardTimer?.cancel();
    if (!mounted || _card == null) return;
    setState(() {
      _card = null;
      if (_mode == _Mode.card) _mode = _Mode.pill;
    });
  }

  void _focusEnded() {
    if (!context.read<SettingsController>().focusEnabled) return;
    _show(
      IslandCardData(kind: IslandCardKind.focus, breakEnded: _focus.isBreak),
      const Duration(seconds: 9),
    );
  }

  void _habitsChanged() {
    final today = IslandToday.of(_habits);
    if (today.key != _perfectDay) {
      _perfectDay = today.key;
      _perfect = today.perfect;
      return;
    }
    if (today.perfect == _perfect) return;
    _perfect = today.perfect;
    if (!today.perfect) return;
    _show(
      IslandCardData(kind: IslandCardKind.perfect, streak: today.best),
      const Duration(seconds: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final focus = context.watch<FocusController>();
    context.watch<HabitsController>();
    context.watch<TodosController>();
    final accent = AppTheme.adaptAccent(settings.accentColor, true);
    final focusing = settings.focusEnabled && focus.isActive;
    final ink = focusing && focus.isBreak ? IslandKit.rest : accent;
    final waits = focusing && focusWaits(focus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _retarget());

    final target = _target();
    final Widget content = switch (_mode) {
      _Mode.open => IslandPanel(
          key: const ValueKey('open'),
          tab: _tab,
          accent: accent,
          locked: _locked,
          onTab: (tab) => setState(() => _tab = tab),
          onTyping: _typingChanged,
          onLeave: () => _setMode(_Mode.pill),
        ),
      _Mode.card => IslandCard(
          key: ValueKey(_card),
          data: _card ?? const IslandCardData(kind: IslandCardKind.perfect),
          accent: accent,
          onDone: _dropCard,
          onOpen: () => _setMode(_Mode.open),
        ),
      _Mode.pill => IslandPill(
          key: ValueKey(focusing ? 'focus' : _locked ? 'locked' : 'idle'),
          accent: ink,
          locked: _locked,
        ),
    };

    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        onEnter: (_) => _enter(),
        onExit: (_) => _exit(),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _morph,
                builder: (context, _) => CustomPaint(
                  painter: IslandPainter(
                    shape: _shape,
                    accent: ink,
                    glow: _mode == _Mode.pill && waits ? 1 : 0,
                    progress: _mode != _Mode.open && focusing && !focus.isFlow
                        ? focus.progress
                        : null,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipPath(
                clipper: _ShapeClip(this),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: const Interval(0.3, 1, curve: Curves.easeOut),
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [...previous, if (current != null) current],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        alignment: Alignment.topCenter,
                        scale: Tween(begin: 0.94, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: SizedBox(
                      key: content.key,
                      width: target.body.width,
                      height: target.body.height,
                      child: _mode == _Mode.pill
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _hoverTimer?.cancel();
                                _setMode(_Mode.open);
                              },
                              child: content,
                            )
                          : content,
                    ),
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

class _ShapeClip extends CustomClipper<Path> {
  _ShapeClip(this.state) : super(reclip: state._morph);

  final _DeskIslandState state;

  @override
  Path getClip(Size size) => state._shape.path();

  @override
  bool shouldReclip(_ShapeClip old) => true;
}
