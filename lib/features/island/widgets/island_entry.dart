import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/island/data/island_piece.dart';
import 'package:streak/features/island/pages/island_page.dart';
import 'package:streak/features/island/state/island_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

class IslandEntry extends StatelessWidget {
  const IslandEntry({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SettingsController>().islandEnabled) {
      return const SizedBox.shrink();
    }
    final island = context.watch<IslandController>();
    final ledger = island.ledgerFor(
      context.watch<HabitsController>().habits,
      context.watch<FocusController>().sessions,
      context.watch<TodosController>().all,
    );
    final balance = island.balanceFrom(ledger);
    final total = islandPieces.length;
    final done = island.built / total;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sea = dark ? const Color(0xFF123246) : const Color(0xFF9FD8EE);
    final grow = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: sea,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => AppNavigator.push(const IslandPage()),
          child: SizedBox(
            height: 132 * (grow < 1.0 ? 1.0 : (grow > 1.9 ? 1.9 : grow)),
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -18,
                  bottom: -26,
                  child: Opacity(
                    opacity: dark ? 0.62 : 0.9,
                    child: Image.asset(
                      'assets/island/preview.webp',
                      fit: BoxFit.contain,
                      cacheHeight: 800,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [sea, sea.withValues(alpha: 0.05)],
                        stops: const [0.42, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.coins,
                            size: 15,
                            color: _ink(dark),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$balance',
                            style: sheetHeadingStyle(
                              context,
                              size: 15,
                              color: _ink(dark),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            island.name.isEmpty
                                ? context.l10n.island_default_name
                                : island.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sheetTitleStyle(
                              context,
                              size: 20,
                              color: _ink(dark),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            island.complete
                                ? context.l10n.island_complete
                                : context.l10n.island_built(
                                    '${island.built}',
                                    '$total',
                                  ),
                            style: sheetBodyStyle(
                              context,
                              size: 12.5,
                              color: _ink(dark).withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 150,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: done,
                                minHeight: 5,
                                color: _ink(dark),
                                backgroundColor:
                                    _ink(dark).withValues(alpha: 0.22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _ink(bool dark) =>
      dark ? const Color(0xFFE9F4FA) : const Color(0xFF11384C);
}
