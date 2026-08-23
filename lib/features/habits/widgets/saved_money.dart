import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/money_format.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/statistics/widgets/express_stat_kit.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

String habitMoneySaved(BuildContext context, Habit habit) => formatMoney(
      habit.moneySaved,
      context.watch<SettingsController>().currency,
      Localizations.localeOf(context).toString(),
    );

Future<void> showCurrencySheet(BuildContext context) {
  final settings = context.read<SettingsController>();
  final options = [...currencySymbols];
  if (settings.currency.isNotEmpty && !options.contains(settings.currency)) {
    options.add(settings.currency);
  }

  return showOptionSheet(
    context,
    title: context.l10n.currency,
    options: [...options, context.l10n.currency_custom],
    index: options.indexOf(settings.currency),
    onSelected: (choice) {
      if (choice < options.length) {
        settings.setCurrency(options[choice]);
        return;
      }
      unawaited(_askCurrency(context, settings));
    },
  );
}

Future<void> _askCurrency(
  BuildContext context,
  SettingsController settings,
) async {
  final value = await showDialog<String>(
    context: context,
    builder: (_) => _CurrencyDialog(initial: settings.currency),
  );
  final trimmed = value?.trim() ?? '';
  if (trimmed.isNotEmpty) await settings.setCurrency(trimmed);
}

class _CurrencyDialog extends StatefulWidget {
  const _CurrencyDialog({required this.initial});

  final String initial;

  @override
  State<_CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends State<_CurrencyDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.currency),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 8,
        decoration: InputDecoration(hintText: context.l10n.currency_hint),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
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
    if (context.watch<SettingsController>().isExpressStyle) {
      return ExpressGroup(
        children: [
          ExpressStatRow(
            icon: LucideIcons.piggyBank,
            label: context.l10n.money_saved,
            value: habitMoneySaved(context, habit),
            tint: context.tokens.success,
            shape: ExpressShape.clover,
          ),
          ExpressStatRow(
            icon: LucideIcons.shieldCheck,
            label: context.l10n.clean_days,
            value: '${habit.cleanDays}',
            tint: habit.color,
            shape: ExpressShape.gem,
          ),
        ],
      );
    }

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
