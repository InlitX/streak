import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

bool canMissOn(Habit habit, DateTime date) {
  final day = date.atMidnight;
  if (habit.kind == HabitKind.negative) {
    return !day.isAfter(AppClock.today()) &&
        !day.isBefore(habit.startedAt) &&
        habit.completions.containsKey(day.dayKey);
  }
  return !habit.tracking &&
      day.isBefore(AppClock.today()) &&
      !day.isBefore(habit.startedAt) &&
      !habit.isCompletedOn(day) &&
      !habit.isNeutralOn(day);
}

List<String> _relapsePresets(BuildContext context) => [
      context.l10n.relapse_stress,
      context.l10n.relapse_bored,
      context.l10n.relapse_craving,
      context.l10n.relapse_social,
      context.l10n.relapse_mood,
      context.l10n.miss_tired,
    ];

List<String> _presets(BuildContext context) => [
      context.l10n.miss_overslept,
      context.l10n.miss_busy,
      context.l10n.miss_traveling,
      context.l10n.miss_sick,
      context.l10n.miss_tired,
      context.l10n.miss_forgot,
    ];

Map<String, int> missedTally(Habit habit) {
  final tally = <String, int>{};
  for (final entry in habit.missReasons.entries) {
    final day = parseDayKey(entry.key);
    if (!canMissOn(habit, day)) continue;
    tally[entry.value] = (tally[entry.value] ?? 0) + 1;
  }
  return Map.fromEntries(
    tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

class MissReasonPicker extends StatefulWidget {
  const MissReasonPicker({super.key, required this.habitId, required this.date});

  final String habitId;
  final DateTime date;

  @override
  State<MissReasonPicker> createState() => _MissReasonPickerState();
}

class _MissReasonPickerState extends State<MissReasonPicker> {
  final _field = TextEditingController();
  bool _typing = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _pick(String? reason) =>
      context.read<HabitsController>().setMissReason(widget.habitId, widget.date.dayKey, reason);

  Future<void> _saveTyped() async {
    final text = _field.text.trim();
    setState(() => _typing = false);
    _field.clear();
    if (text.isNotEmpty) await _pick(text);
  }

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitsController>().byId(widget.habitId);
    if (habit == null || !canMissOn(habit, widget.date)) return const SizedBox.shrink();
    final color = habit.color.shownIn(context);
    final chosen = habit.missReasons[widget.date.dayKey];
    final options = {
      ...habit.kind == HabitKind.negative
          ? _relapsePresets(context)
          : _presets(context),
      ...habit.missReasons.values,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              habit.kind == HabitKind.negative
                  ? context.l10n.relapse_reason_title
                  : context.l10n.miss_reason_title,
              style: sheetLabelStyle(context),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in options)
                ChoiceChip(
                  label: Text(reason),
                  selected: reason == chosen,
                  showCheckmark: false,
                  selectedColor: color.withValues(alpha: 0.22),
                  onSelected: (on) => _pick(on ? reason : null),
                ),
              if (!_typing)
                ActionChip(
                  avatar: const Icon(LucideIcons.plus, size: 15),
                  label: Text(context.l10n.miss_other),
                  onPressed: () => setState(() => _typing = true),
                ),
            ],
          ),
          if (_typing) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _field,
                    hint: context.l10n.miss_other_hint,
                    autofocus: true,
                  ),
                ),
                IconButton(
                  onPressed: _saveTyped,
                  icon: Icon(LucideIcons.check, color: color),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MissReasonsTile extends StatelessWidget {
  const MissReasonsTile({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final tally = missedTally(habit);
    if (tally.isEmpty) return const SizedBox.shrink();
    final settings = context.watch<SettingsController>();
    final summary = tally.entries.take(3).map((e) => '${e.key} ${e.value}').join('  ·  ');
    final title = habit.kind == HabitKind.negative
        ? context.l10n.relapse_reasons
        : context.l10n.miss_reasons;
    void open() => _showMissReasons(context, tally, title);

    final Widget tile;
    if (settings.isExpressStyle) {
      tile = ExpressTile(
        icon: LucideIcons.messageCircleQuestion,
        title: title,
        subtitle: summary,
        onTap: open,
      );
    } else if (settings.isMinimalStyle) {
      tile = MinimalList(
        children: [
          MinimalRow(label: title, caption: summary, onTap: open, last: true),
        ],
      );
    } else {
      tile = Card(
        child: ListTile(
          onTap: open,
          leading: Icon(LucideIcons.messageCircleQuestion, size: 22, color: context.colors.primary),
          title: Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.onSurface),
          ),
          subtitle: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.tokens.muted),
          ),
          trailing: Icon(LucideIcons.chevronRight, size: 18, color: context.tokens.muted),
        ),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: tile);
  }
}

Future<void> _showMissReasons(
  BuildContext context,
  Map<String, int> tally,
  String title,
) {
  final total = tally.values.fold<int>(0, (sum, n) => sum + n);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(title),
            const SizedBox(height: 8),
            for (final entry in tally.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key, style: sheetOptionStyle(sheet, size: 14.5))),
                        Text('${entry.value}', style: sheetHeadingStyle(sheet, size: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        minHeight: 6,
                        backgroundColor: sheet.colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
