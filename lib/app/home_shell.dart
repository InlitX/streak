import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_nav.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/minimal/minimal_nav.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/services/home_widget_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _Tab { today, todos, stats, settings }

final _paneTab = ValueNotifier(_Tab.today);

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  _Tab _tab = _Tab.today;

  double _direction = 1;

  late final AnimationController _swap;
  late final Animation<double> _fade = CurvedAnimation(
    parent: _swap,
    curve: const Interval(0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<double> _ease = CurvedAnimation(
    parent: _swap,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _paneTab.value = _tab;
    _swap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _swap.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(List<_Tab> tabs, _Tab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    if (tab == _Tab.today) TodayIntro.replay();
    setState(() {
      _direction = tabs.indexOf(tab) > tabs.indexOf(_tab) ? 1 : -1;
      _tab = tab;
    });
    _paneTab.value = tab;
    AppNavigator.clearPane();
    _swap.forward(from: 0);
  }

  Widget _rail(
    BuildContext context,
    List<_Tab> tabs,
    _Tab current,
    int style,
  ) {
    final index = tabs.indexOf(current);
    if (style == 2) {
      return ExpressNavRail(
        items: [
          for (final tab in tabs)
            ExpressNavItem(icon: _iconOf(tab), label: _labelOf(context, tab)),
        ],
        index: index,
        onSelect: (i) => _select(tabs, tabs[i]),
        brand: const _RailBrand(),
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
        brand: const _RailBrand(),
      );
    }
    return _NavRail(
      tabs: tabs,
      current: current,
      onSelect: (tab) => _select(tabs, tab),
    );
  }

  void _swipe(List<_Tab> tabs, double velocity) {
    final next = tabs.indexOf(_tab) + (velocity < 0 ? 1 : -1);
    if (next < 0 || next >= tabs.length) return;
    _select(tabs, tabs[next]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final habits = context.read<HabitsController>();
      habits.reload().then((_) => HomeWidgetService.sync(habits.asMap));
      context.read<TodosController>().reload();
      TodayIntro.replay();
      drainFocusActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final wide = isWideLayout(context);
    final minimal = settings.isMinimalStyle;
    if (minimal && !wide) return const Scaffold(body: HomePage());
    final scheme = Theme.of(context).colorScheme;
    final express = settings.isExpressStyle;
    final tabs = [
      _Tab.today,
      if (settings.todosEnabled) _Tab.todos,
      _Tab.stats,
      _Tab.settings,
    ];
    final current = tabs.contains(_tab) ? _tab : _Tab.today;

    if (wide) {
      return _SplitScaffold(
        full: current == _Tab.stats,
        rail: _rail(context, tabs, current, settings.appStyle),
        page: FadeTransition(
          opacity: _fade,
          child: IndexedStack(
            index: tabs.indexOf(current),
            children: [for (final tab in tabs) _pageOf(tab)],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) =>
                _swipe(tabs, details.primaryVelocity ?? 0),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(0.07 * _direction, 0),
                  end: Offset.zero,
                ).animate(_ease),
                child: IndexedStack(
                  index: tabs.indexOf(current),
                  children: [for (final tab in tabs) _pageOf(tab)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
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
                  : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final tab in tabs)
                      _NavItem(
                        icon: _iconOf(tab),
                        label: _labelOf(context, tab),
                        selected: tab == current,
                        onTap: () => _select(tabs, tab),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _pageOf(_Tab tab) => switch (tab) {
      _Tab.today => const HomePage(),
      _Tab.todos => const TodosPage(),
      _Tab.stats => const StatisticsPage(),
      _Tab.settings => const SettingsPage(),
    };

IconData _iconOf(_Tab tab) => switch (tab) {
      _Tab.today => LucideIcons.house,
      _Tab.todos => LucideIcons.listChecks,
      _Tab.stats => LucideIcons.chartColumn,
      _Tab.settings => LucideIcons.settings,
    };

String _labelOf(BuildContext context, _Tab tab) => switch (tab) {
      _Tab.today => context.l10n.today,
      _Tab.todos => context.l10n.todos,
      _Tab.stats => context.l10n.stats,
      _Tab.settings => context.l10n.settings,
    };

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final scheme = Theme.of(context).colorScheme;
    final tint = selected ? scheme.primary : context.tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 18 : 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: selected ? 0.16 : 0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    child: Icon(icon, size: 21, color: tint),
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 88),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tint,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitScaffold extends StatefulWidget {
  const _SplitScaffold({this.rail, required this.page, this.full = false});

  final Widget? rail;
  final Widget page;
  final bool full;

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
          if (widget.full)
            Expanded(child: widget.page)
          else ...[
            SizedBox(width: paneWidth, child: widget.page),
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
    required this.onSelect,
  });

  static const _width = 212.0;

  final List<_Tab> tabs;
  final _Tab current;
  final void Function(_Tab tab) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _RailBrand(),
              const SizedBox(height: 26),
              for (final tab in tabs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _RailItem(
                    icon: _iconOf(tab),
                    label: _labelOf(context, tab),
                    selected: tab == current,
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
  const _RailBrand();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
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
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
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
            child: Row(
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
