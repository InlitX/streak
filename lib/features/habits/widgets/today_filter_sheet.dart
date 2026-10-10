import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_switch.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

bool todayFiltered(SettingsController settings) =>
    settings.todayOnly || settings.hideDone || settings.hideTracking;

Future<void> showTodayFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _TodayFilterSheet(),
  );
}

class _TodayFilterSheet extends StatelessWidget {
  const _TodayFilterSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final tracked = context.select<HabitsController, bool>(
      (habits) => habits.habits.any((habit) => habit.tracking),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.today_filter,
              style: sheetTitleStyle(context, size: 18),
            ),
            const SizedBox(height: 18),
            _FilterRow(
              icon: LucideIcons.calendarCheck,
              title: context.l10n.today_only,
              subtitle: context.l10n.today_only_sub,
              value: settings.todayOnly,
              onChanged: settings.setTodayOnly,
            ),
            const SizedBox(height: 18),
            _FilterRow(
              icon: LucideIcons.listChecks,
              title: context.l10n.hide_done,
              subtitle: context.l10n.hide_done_sub,
              value: settings.hideDone,
              onChanged: settings.setHideDone,
            ),
            if (tracked || settings.hideTracking) ...[
              const SizedBox(height: 18),
              _FilterRow(
                icon: LucideIcons.eyeOff,
                title: context.l10n.tracking_hide,
                subtitle: context.l10n.tracking_hide_sub,
                value: settings.hideTracking,
                onChanged: settings.setHideTracking,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final express = context.watch<SettingsController>().isExpressStyle;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.tokens.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: sheetHeadingStyle(context)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: sheetBodyStyle(context, size: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (express)
              ExpressSwitch(value: value, onChanged: onChanged)
            else
              Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class TodayAllDone extends StatelessWidget {
  const TodayAllDone({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(LucideIcons.circleCheckBig, size: 36, color: context.tokens.muted),
          const SizedBox(height: 12),
          Text(
            context.l10n.all_done_today,
            textAlign: TextAlign.center,
            style: sheetHeadingStyle(context, size: 16),
          ),
        ],
      ),
    );
  }
}
