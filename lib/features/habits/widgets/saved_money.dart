import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/money_format.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

String habitMoneySaved(BuildContext context, Habit habit) => formatMoney(
      habit.moneySaved,
      context.watch<SettingsController>().currency,
      Localizations.localeOf(context).toString(),
    );

Future<void> showCurrencySheet(BuildContext context) {
  final settings = context.read<SettingsController>();
  return showOptionSheet(
    context,
    title: context.l10n.currency,
    options: currencySymbols,
    index: currencySymbols.indexOf(settings.currency),
    onSelected: (index) => settings.setCurrency(currencySymbols[index]),
  );
}

class SavedMoneyCard extends StatelessWidget {
  const SavedMoneyCard({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final symbol = context.watch<SettingsController>().currency;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(LucideIcons.piggyBank, size: 22, color: context.tokens.success),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.money_saved,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.l10n.count_days(habit.cleanDays)}  ·  '
                    '${formatMoney(habit.dailyCost, symbol, locale)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatMoney(habit.moneySaved, symbol, locale),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.tokens.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedMoneyStats extends StatelessWidget {
  const SavedMoneyStats({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return StatPair(
      left: MiniStat(
        icon: LucideIcons.piggyBank,
        color: context.tokens.success,
        value: habitMoneySaved(context, habit),
        label: context.l10n.money_saved,
      ),
      right: MiniStat(
        icon: LucideIcons.shieldCheck,
        color: habit.color,
        value: '${habit.cleanDays}',
        label: context.l10n.clean_days,
      ),
    );
  }
}
