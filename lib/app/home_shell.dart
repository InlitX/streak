import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/pages/settings_page.dart';
import 'package:streak/features/statistics/pages/statistics_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _pages = [HomePage(), StatisticsPage(), SettingsPage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HabitsController>().reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2E)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.house),
            label: context.l10n.today,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.chartColumn),
            label: context.l10n.stats,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.settings),
            label: context.l10n.settings,
          ),
        ],
        ),
      ),
    );
  }
}
