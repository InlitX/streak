import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/money_format.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/widgets/number_keypad_dialog.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

bool isRelapse(Habit habit, DateTime date) =>
    habit.completions.containsKey(date.dayKey);

Future<double?> askRelapse(BuildContext context, Habit habit) async {
  final spent = ValueNotifier(habit.dailyCost);
  final confirmed = await showAppConfirmDialog(
    context,
    title: context.l10n.log_relapse_title,
    message: context.l10n.log_relapse_body(habit.name),
    confirmLabel: context.l10n.log_relapse_confirm,
    icon: LucideIcons.ban,
    body: habit.logsSpent
        ? ValueListenableBuilder<double>(
            valueListenable: spent,
            builder: (_, value, _) => SpentField(
              value: value,
              onChanged: (next) => spent.value = next,
            ),
          )
        : null,
  );
  final value = spent.value;
  spent.dispose();
  if (confirmed != true) return null;
  return habit.logsSpent ? value : 0;
}

Future<double?> pickSpent(BuildContext context, double current) =>
    showNumberKeypadDialog(
      context,
      title: context.l10n.relapse_spent,
      value: current,
      unit: context.read<SettingsController>().currency,
      decimals: true,
      accent: context.tokens.danger,
    );

class SpentField extends StatelessWidget {
  const SpentField({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final danger = context.tokens.danger;
    final symbol = context.watch<SettingsController>().currency;
    final locale = Localizations.localeOf(context).toString();
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () async {
          final picked = await pickSpent(context, value);
          if (picked != null) onChanged(picked < 0 ? 0 : picked);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: danger.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.wallet, size: 20, color: danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.relapse_spent,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(value, symbol, locale),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.pencil, size: 16, color: context.tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}
