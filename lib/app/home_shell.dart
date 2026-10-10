import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/app/classic_nav_bar.dart';
import 'package:streak/core/express/express_nav.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/minimal/minimal_nav.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/database/local_store.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/routing/back_handlers.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/page_motion.dart';
import 'package:streak/core/widgets/glass.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/pages/day_timeline_page.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/settings/settings_actions.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/services/auto_sync.dart';
import 'package:streak/services/home_widget_service.dart';
import 'package:streak/services/widget_action_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static void showSettings() {
    AppNavigator.key.currentState?.popUntil((route) => route.isFirst);
    _toSettings.value++;
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _Tab { today, todos, plan, stats, settings }

final _paneTab = ValueNotifier(_Tab.today);

final _toSettings = ValueNotifier(0);

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  _Tab _tab = _Tab.today;

  final _visited = <_Tab>{_Tab.today};

  late final AnimationController _swap;
  final _compact = ValueNotifier(false);
  Timer? _nextDay;
  DateTime? _leftAt;
  bool _replayDue = false;

  static const _awayForReplay = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _paneTab.value = _tab;
    _swap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
    WidgetsBinding.instance.addObserver(this);
    _toSettings.addListener(_openSettings);
    final focus = context.read<FocusController>();
    final habits = context.read<HabitsController>();
    focus.onRoundSaved =
        (session) => unawaited(creditFocusRound(habits, focus, session));
    _waitForNextDay();
    final settings = context.read<SettingsController>();
    AutoSync.start(
      enabled: () => settings.syncsFolder,
      reload: () async {
        if (mounted) await SettingsActions.reloadAll(context);
      },
      save: () => settings.runAutoBackup(force: true, archive: false),
    );
  }

  void _waitForNextDay() {
    _nextDay?.cancel();
    final end = AppClock.today()
        .addDays(1)
        .add(Duration(hours: AppClock.cutoffHour, seconds: 1));
    _nextDay = Timer(end.difference(DateTime.now()), () {
      if (!mounted) return;
      context.read<HabitsController>().refresh();
      context.read<TodosController>().reload();
      _waitForNextDay();
    });
  }

  @override
  void dispose() {
    _nextDay?.cancel();
    AutoSync.stop();
    _swap.dispose();
    _compact.dispose();
    _toSettings.removeListener(_openSettings);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(List<_Tab> tabs, _Tab tab) {
    if (tab == _tab) return;
    if (tab == _Tab.today && _replayDue) {
      _replayDue = false;
      TodayIntro.replay();
    }
    setState(() {
      _visited.add(tab);
      _tab = tab;
    });
    _paneTab.value = tab;
    AppNavigator.clearPane();
    _compact.value = false;
    _swap.forward(from: 0);
  }

  void _openSettings() {
    setState(() {
      _visited.add(_Tab.settings);
      _tab = _Tab.settings;
    });
    _paneTab.value = _Tab.settings;
  }

  bool _onScroll(ScrollUpdateNotification note) {
    final delta = note.scrollDelta ?? 0;
    if (note.metrics.axis != Axis.vertical) return false;
    if (note.metrics.pixels <= note.metrics.minScrollExtent + 8) {
      _compact.value = false;
    } else if (note.dragDetails == null) {
      return false;
    } else if (delta > 4) {
      _compact.value = true;
    } else if (delta < -4) {
      _compact.value = false;
    }
    return false;
  }

  Widget _rail(
    BuildContext context,
    List<_Tab> tabs,
    _Tab current,
    int style,
  ) {
    final index = tabs.indexOf(current);
    final compact = isCompactRail(context);
    if (style == 2) {
      return ExpressNavRail(
        items: [
          for (final tab in tabs)
            ExpressNavItem(icon: _iconOf(tab), label: _labelOf(context, tab)),
        ],
        index: index,
        onSelect: (i) => _select(tabs, tabs[i]),
        brand: _RailBrand(compact: compact),
        compact: compact,
      );
    }
    if (style == 1) {
      return MinimalNavRail(
        items: [
          for (final tab in tabs)
            MinimalNavItem(icon: _iconOf(tab), label: _labelOf(context, tab)),
        ],
        index: index,
        onSelect: (i) => _select(tabs, tabs[i]),
        brand: _RailBrand(compact: compact),
        compact: compact,
      );
    }
    return _NavRail(
      tabs: tabs,
      current: current,
      compact: compact,
      onSelect: (tab) => _select(tabs, tab),
    );
  }

  void _back(List<_Tab> tabs, _Tab current) {
    if (BackHandlers.handle()) return;
    if (current != _Tab.today) {
      _select(tabs, _Tab.today);
      return;
    }
    SystemNavigator.pop();
  }

  Widget _guard(List<_Tab> tabs, _Tab current, Widget child) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back(tabs, current);
        },
        child: child,
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _leftAt ??= DateTime.now();
      unawaited(AutoSync.pause());
    }
    if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (left != null && DateTime.now().difference(left) >= _awayForReplay) {
        _replayDue = _tab != _Tab.today;
        if (!_replayDue) TodayIntro.replay();
      }
      final habits = context.read<HabitsController>();
      if (Platform.isIOS) _applyWidgetActions(habits);
      habits.refresh().then((_) => HomeWidgetService.sync(habits.asMap));
      context.read<TodosController>().refresh();
      drainFocusActions();
      context.read<SettingsController>().runAutoBackup();
      AutoSync.resume();
      _waitForNextDay();
    }
  }

  Future<void> _applyWidgetActions(HabitsController habits) async {
    final todos = context.read<TodosController>();
    final changed = await WidgetActionService.drain(
      LocalStore.readHabits(),
      todos: LocalStore.readTodos(),
    );
    if (!changed) return;
    await habits.reload();
    todos.reload();
    await HomeWidgetService.sync(habits.asMap);
  }

  @override
  Widget build(BuildContext context) =>
      _StableMedia(child: Builder(builder: _layout));

  Widget _layout(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final wide = isWideLayout(context);
    final railed = hasSideRail(context);
    final minimal = settings.isMinimalStyle;
    if (minimal && !railed) {
      return _guard(
        const [_Tab.today],
        _Tab.today,
        const Scaffold(resizeToAvoidBottomInset: false, body: HomePage()),
      );
    }
    final express = settings.isExpressStyle;
    final tabs = [
      _Tab.today,
      if (settings.todosEnabled) _Tab.todos,
      if (settings.planningEnabled) _Tab.plan,
      _Tab.stats,
      _Tab.settings,
    ];
    final current = tabs.contains(_tab) ? _tab : _Tab.today;

    if (railed) {
      return _guard(
        tabs,
        current,
        _SplitScaffold(
        full: current == _Tab.stats,
        single: !wide,
        rail: _rail(context, tabs, current, settings.appStyle),
        page: FadeThrough(
          animation: _swap,
          child: IndexedStack(
            index: tabs.indexOf(current),
            children: [
              for (final tab in tabs)
                TickerMode(
                  enabled: tab == current,
                  child: _visited.contains(tab)
                      ? _pageOf(tab)
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
      );
    }

    return _guard(
      tabs,
      current,
      Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          NotificationListener<ScrollUpdateNotification>(
            onNotification: _onScroll,
            child: FadeThrough(
            animation: _swap,
            child: IndexedStack(
              index: tabs.indexOf(current),
              children: [
                for (final tab in tabs)
                  TickerMode(
                    enabled: tab == current,
                    child: _visited.contains(tab)
                        ? _pageOf(tab)
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
          ),
          if (!express)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: EdgeBlur(
                top: false,
                height: 104 + MediaQuery.viewPaddingOf(context).bottom,
                sigma: 12,
                shade: 0.6,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
            child: Center(
              child: express
                  ? ExpressNavBar(
                      items: [
                        for (final tab in tabs)
                          ExpressNavItem(
                            icon: _iconOf(tab),
                            label: _labelOf(context, tab),
                          ),
                      ],
                      index: tabs.indexOf(current),
                      onSelect: (i) => _select(tabs, tabs[i]),
                    )
                  : ClassicNavBar(
                      items: [
                        for (final tab in tabs)
                          (icon: _iconOf(tab), label: _labelOf(context, tab)),
                      ],
                      index: tabs.indexOf(current),
                      onSelect: (i) => _select(tabs, tabs[i]),
                      compact: _compact,
                    ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

Widget _pageOf(_Tab tab) => switch (tab) {
      _Tab.today => const HomePage(),
      _Tab.todos => const TodosPage(),
      _Tab.plan => const DayTimelinePage(),
      _Tab.stats => const StatisticsPage(),
      _Tab.settings => const SettingsPage(),
    };

IconData _iconOf(_Tab tab) => switch (tab) {
      _Tab.today => LucideIcons.house,
      _Tab.todos => LucideIcons.listChecks,
      _Tab.plan => LucideIcons.calendarClock,
      _Tab.stats => LucideIcons.chartColumn,
      _Tab.settings => LucideIcons.settings,
    };

String _labelOf(BuildContext context, _Tab tab) => switch (tab) {
      _Tab.today => context.l10n.today,
      _Tab.todos => context.l10n.todos,
      _Tab.plan => context.l10n.plan_tab,
      _Tab.stats => context.l10n.stats,
      _Tab.settings => context.l10n.settings,
    };

class _StableMedia extends StatefulWidget {
  const _StableMedia({required this.child});

  final Widget child;

  @override
  State<_StableMedia> createState() => _StableMediaState();
}

class _StableMediaState extends State<_StableMedia> {
  MediaQueryData? _kept;

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.of(context);
    final current = ModalRoute.isCurrentOf(context) ?? true;
    final kept = _kept;
    if (current || kept == null || kept.size != live.size) _kept = live;
    return MediaQuery(data: _kept!, child: widget.child);
  }
}

class _SplitScaffold extends StatefulWidget {
  const _SplitScaffold({
    this.rail,
    required this.page,
    this.full = false,
    this.single = false,
  });

  final Widget? rail;
  final Widget page;
  final bool full;
  final bool single;

  @override
  State<_SplitScaffold> createState() => _SplitScaffoldState();
}

class _SplitScaffoldState extends State<_SplitScaffold> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    final root = AppNavigator.key.currentState;
    if (root == null || root.canPop()) return false;
    final pane = AppNavigator.paneKey.currentState;
    if (pane == null || !pane.canPop()) return false;
    AppNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final tint = settings.isMinimalStyle
        ? minimalSurface(context).withValues(alpha: 0.5)
        : settings.isExpressStyle
        ? Theme.of(context).colorScheme.surfaceContainerLowest
        : null;

    return Scaffold(
      body: Row(
        children: [
          if (widget.rail != null) ...[
            tint == null
                ? widget.rail!
                : ColoredBox(color: tint, child: widget.rail!),
            const _Line(),
          ],
          if (widget.single)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: railPageWidth),
                  child: widget.page,
                ),
              ),
            )
          else if (widget.full)
            Expanded(child: widget.page)
          else ...[
            SizedBox(
              width: isCompactRail(context) ? compactPaneWidth : paneWidth,
              child: widget.page,
            ),
            const _Line(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: detailWidth),
                  child: const SizedBox.expand(child: _DetailPane()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: settings.isMinimalStyle
          ? minimalLineColor(context)
          : settings.isExpressStyle
          ? expressHairlineColor(context)
          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.32),
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: AppNavigator.paneKey,
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => ValueListenableBuilder<_Tab>(
          valueListenable: _paneTab,
          builder: (_, tab, __) => _DetailPlaceholder(tab: tab),
        ),
      ),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder({required this.tab});

  final _Tab tab;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final scheme = Theme.of(context).colorScheme;
    final muted = context.tokens.muted;
    final express = settings.isExpressStyle;
    final minimal = settings.isMinimalStyle;

    final tile = Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: express
          ? ShapeDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: const ExpressBorder(shape: ExpressShape.cookie),
            )
          : BoxDecoration(
              color: minimal
                  ? minimalRaised(context)
                  : scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(minimal ? 26 : 46),
            ),
      child: Icon(
        _iconOf(tab),
        size: 34,
        color: minimal ? muted : scheme.primary.withValues(alpha: 0.75),
      ),
    );

    final title = _labelOf(context, tab);
    final titleStyle = express
        ? ExpressType.display.at(21, spacing: -0.2, color: scheme.onSurface)
        : minimal
        ? MinimalType.title(19, weight: 700, color: scheme.onSurface)
        : TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          );
    final hintStyle = express
        ? ExpressType.body.at(13.5, color: muted)
        : minimal
        ? MinimalType.body(13.5, color: muted)
        : TextStyle(fontSize: 13.5, color: muted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile,
            const SizedBox(height: 20),
            Text(title, style: titleStyle),
            const SizedBox(height: 8),
            Text(
              context.l10n.pane_hint,
              textAlign: TextAlign.center,
              style: hintStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.tabs,
    required this.current,
    required this.compact,
    required this.onSelect,
  });

  static const _width = 212.0;

  final List<_Tab> tabs;
  final _Tab current;
  final bool compact;
  final void Function(_Tab tab) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 76 : _width,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 14, 22, compact ? 12 : 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RailBrand(compact: compact),
              const SizedBox(height: 26),
              for (final tab in tabs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _RailItem(
                    icon: _iconOf(tab),
                    label: _labelOf(context, tab),
                    selected: tab == current,
                    compact: compact,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: compact ? 0 : 6),
      child: Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/icon.png',
              width: 30,
              height: 30,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (!compact) ...[
          const SizedBox(width: 10),
          Text(
            'Streak',
            style: settings.isExpressStyle
                ? ExpressType.headline.at(
                    17,
                    weight: 800,
                    color: scheme.onSurface,
                  )
                : settings.isMinimalStyle
                ? MinimalType.title(17, weight: 700, color: scheme.onSurface)
                : TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
          ),
          ],
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = selected ? scheme.primary : context.tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: selected ? 0.14 : 0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: compact
                ? Tooltip(
                    message: label,
                    child: Icon(icon, size: 19, color: tint),
                  )
                : Row(
              children: [
                Icon(icon, size: 19, color: tint),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: tint,
                    ),
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
