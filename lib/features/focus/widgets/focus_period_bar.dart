import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/data/focus_stats.dart';

String focusPeriodLabel(
  BuildContext context,
  FocusRange range,
  int offset,
  DateTime start,
) {
  final locale = Localizations.localeOf(context).toString();
  switch (range) {
    case FocusRange.week:
      if (offset == 0) return context.l10n.period_this_week;
      if (offset == -1) return context.l10n.period_last_week;
      return context.l10n.period_week_of(DateFormat.MMMd(locale).format(start));
    case FocusRange.month:
      if (offset == 0) return context.l10n.period_this_month;
      if (offset == -1) return context.l10n.period_last_month;
      return DateFormat.yMMMM(locale).format(start);
    case FocusRange.year:
      if (offset == 0) return context.l10n.period_this_year;
      if (offset == -1) return context.l10n.period_last_year;
      return '${start.year}';
  }
}

class FocusPeriodBar extends StatelessWidget {
  const FocusPeriodBar({
    super.key,
    required this.range,
    required this.offset,
    required this.stats,
    required this.onOffset,
    this.accent,
  });

  final FocusRange range;
  final int offset;
  final FocusStats stats;
  final ValueChanged<int> onOffset;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? context.colors.primary;
    final label = focusPeriodLabel(context, range, offset, stats.buckets.first);
    final summary = stats.rangeCount == 0
        ? context.l10n.focus_period_sessions(0)
        : '${formatHoursShort(stats.rangeSeconds)}  ·  '
            '${context.l10n.focus_period_sessions(stats.rangeCount)}';

    return Row(
      children: [
        _Arrow(
          icon: LucideIcons.chevronLeft,
          tooltip: context.l10n.a11y_previous_week,
          onTap: () => onOffset(offset - 1),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: sheetHeadingStyle(context, size: 14.5, color: tint),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: sheetLabelStyle(context, size: 11.5),
              ),
            ],
          ),
        ),
        _Arrow(
          icon: LucideIcons.chevronRight,
          tooltip: context.l10n.a11y_next_week,
          onTap: offset < 0 ? () => onOffset(offset + 1) : null,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = sheetStyle(context);
    final muted = context.tokens.muted;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.25,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(
                alpha: style == 0 ? 0 : 0.55,
              ),
              borderRadius: BorderRadius.circular(style == 2 ? 18 : 12),
            ),
            child: Icon(icon, size: 17, color: muted),
          ),
        ),
      ),
    );
  }
}
