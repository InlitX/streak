import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class SecondChancesCard extends StatelessWidget {
  const SecondChancesCard({super.key, required this.habit});

  final Habit habit;

  void _explain(BuildContext context) => showAppConfirmDialog(
        context,
        title: context.l10n.second_chances,
        message: context.l10n.chances_info,
        confirmLabel: context.l10n.chances_ok,
        icon: LucideIcons.heartHandshake,
        danger: false,
        single: true,
      );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final accent = habit.color.shownIn(context);
    final left = habit.chancesLeft;
    final saved = habit.savedDays;
    final next = Habit.chanceEvery - habit.currentStreak % Habit.chanceEvery;
    final title = left > 0
        ? context.l10n.chances_left(left)
        : context.l10n.chances_next(next);
    final note = saved.isEmpty
        ? null
        : context.l10n.chance_used(
            DateFormat.MMMd(Localizations.localeOf(context).toString())
                .format(saved.last),
          );

    final row = Row(
      children: [
        for (var i = 0; i < Habit.chanceCap; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              i < left ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: i < left ? accent : context.tokens.muted.withValues(alpha: 0.5),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
              if (note != null)
                Text(
                  note,
                  style: TextStyle(fontSize: 12, color: context.tokens.muted),
                ),
            ],
          ),
        ),
        Icon(LucideIcons.info, size: 16, color: context.tokens.muted),
      ],
    );

    final padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _explain(context),
        child: settings.isExpressStyle
            ? ExpressCard(padding: padding, child: row)
            : settings.isMinimalStyle
            ? Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: row)
            : Card(child: Padding(padding: padding, child: row)),
      ),
    );
  }
}
