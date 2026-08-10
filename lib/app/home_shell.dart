import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/widgets/today_intro.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';
import 'package:streak/features/todos/pages/todos_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _Tab { today, todos, stats, settings }

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
    _swap.forward(from: 0);
  }

  void _swipe(List<_Tab> tabs, double velocity) {
    final next = tabs.indexOf(_tab) + (velocity < 0 ? 1 : -1);
    if (next < 0 || next >= tabs.length) return;
    _select(tabs, tabs[next]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HabitsController>().reload();
      TodayIntro.replay();
      drainFocusActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    if (settings.isMinimalStyle) {
      return const Scaffold(body: HomePage());
    }
    final scheme = Theme.of(context).colorScheme;
    final tabs = [
      _Tab.today,
      if (settings.todosEnabled) _Tab.todos,
      _Tab.stats,
      _Tab.settings,
    ];
    final current = tabs.contains(_tab) ? _tab : _Tab.today;

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
              child: Container(
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
