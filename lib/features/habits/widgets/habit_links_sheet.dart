import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_switch.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/amount_format.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/data/habit_links.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

Future<void> showHabitLinksSheet(BuildContext context, {required Habit habit}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _HabitLinksSheet(habit: habit),
  );
}

class _HabitLinksSheet extends StatelessWidget {
  const _HabitLinksSheet({required this.habit});

  final Habit habit;

  List<(String, String)> _links(BuildContext context, bool focus) {
    final l10n = context.l10n;
    final negative = habit.kind == HabitKind.negative;
    final adds = habit.kind == HabitKind.quantitative && !habit.needsFocusSession;
    return [
      if (negative) (l10n.habit_link_relapse, HabitLinks.relapse(habit)),
      if (adds)
        (
          l10n.habit_link_add(habit.isTimeAmount
              ? formatMinutes(habit.incrementAmount)
              : formatAmount(habit.incrementAmount)),
          HabitLinks.add(habit),
        ),
      if (!negative && !habit.needsFocusSession)
        (l10n.habit_link_done, HabitLinks.done(habit)),
      (l10n.habit_link_undo, HabitLinks.undo(habit)),
      if (focus && !negative) (l10n.habit_link_focus, HabitLinks.focus(habit)),
      (l10n.habit_link_open, HabitLinks.open(habit)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final express = settings.isExpressStyle;
    final on = settings.habitLinks;
    final accent = context.tokens.info;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (express)
                  ExpressBlob(
                    size: 44,
                    color: accent.withValues(alpha: 0.18),
                    shape: ExpressShape.flower,
                    child: Icon(LucideIcons.link, size: 20, color: accent),
                  )
                else
                  Icon(LucideIcons.link, size: 22, color: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.l10n.habit_links,
                    style: sheetTitleStyle(context, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                if (express)
                  ExpressSwitch(
                    value: on,
                    tint: accent,
                    onChanged: settings.setHabitLinks,
                  )
                else
                  Switch(value: on, onChanged: settings.setHabitLinks),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              on ? context.l10n.habit_links_on : context.l10n.habit_links_off,
              style: sheetBodyStyle(context, size: 13),
            ),
            if (on) ...[
              const SizedBox(height: 16),
              for (final (label, link) in _links(context, settings.focusEnabled))
                _LinkRow(label: label, link: link),
              const SizedBox(height: 10),
              Text(
                context.l10n.habit_link_day,
                style: sheetBodyStyle(context, size: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatefulWidget {
  const _LinkRow({required this.label, required this.link});

  final String label;
  final String link;

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.link));
    _reset?.cancel();
    setState(() => _copied = true);
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: sheetOptionStyle(context)),
                  const SizedBox(height: 2),
                  Text(
                    widget.link,
                    style: sheetBodyStyle(context, size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              _copied ? LucideIcons.check : LucideIcons.copy,
              size: 18,
              color: _copied ? context.tokens.success : context.tokens.muted,
            ),
          ],
        ),
      ),
    );
  }
}
