import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/statistics/data/habit_stats.dart';

ConsistencyPeriod consistencyPeriodOf(BuildContext context) {
  final index = context.watch<SettingsController>().consistencyPeriod;
  return ConsistencyPeriod.values[index.clamp(0, ConsistencyPeriod.values.length - 1)];
}

String consistencyCaption(BuildContext context, ConsistencyPeriod period) =>
    switch (period) {
      ConsistencyPeriod.week => context.l10n.last_7_days,
      ConsistencyPeriod.month => context.l10n.last_30_days,
      ConsistencyPeriod.quarter => context.l10n.last_90_days,
      ConsistencyPeriod.year => context.l10n.last_12_months,
    };

String? consistencyDelta(ConsistencyValue value) {
  final before = value.before;
  if (before == null) return null;
  final delta = value.now - before;
  final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '±');
  return '$sign${delta.abs()}%';
}

String? consistencyChange(BuildContext context, ConsistencyValue value) {
  final delta = consistencyDelta(value);
  return delta == null ? null : context.l10n.consistency_vs_previous(delta);
}

Future<void> pickConsistencyPeriod(BuildContext context) {
  final settings = context.read<SettingsController>();
  return showOptionSheet(
    context,
    title: context.l10n.completion_rate_short,
    options: [
      for (final period in ConsistencyPeriod.values)
        consistencyCaption(context, period),
    ],
    index: settings.consistencyPeriod,
    onSelected: settings.setConsistencyPeriod,
  );
}
