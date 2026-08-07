import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

const _entrance = Duration(milliseconds: 340);

class FocusHistoryPage extends StatefulWidget {
  const FocusHistoryPage({super.key, this.habitId});

  final String? habitId;

  @override
  State<FocusHistoryPage> createState() => _FocusHistoryPageState();
}

class _FocusHistoryPageState extends State<FocusHistoryPage> {
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _selectAll(List<FocusSession> sessions) {
    setState(() {
      if (_selected.length == sessions.length) {
        _selected.clear();
      } else {
        _selected.addAll(sessions.map((s) => s.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.focus_delete_sessions,
      message: context.l10n.focus_delete_sessions_body(count),
      confirmLabel: context.l10n.delete,
    );
    if (confirmed != true || !mounted) return;

    await context.read<FocusController>().removeSessions({..._selected});
    if (!mounted) return;
    setState(_selected.clear);
    AppSnackbar.success(context, context.l10n.focus_sessions_deleted(count));
  }

  String _title(BuildContext context) {
    final id = widget.habitId;
    if (id == null) return context.l10n.focus_history;
    return context.read<HabitsController>().byId(id)?.name ??
        context.l10n.focus_history;
  }

  PreferredSizeWidget _appBar(BuildContext context, List<FocusSession> all) {
    if (!_selecting) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: Text(_title(context)),
      );
    }
    return AppBar(
      leading: IconButton(
        icon: const Icon(LucideIcons.x),
        tooltip: context.l10n.cancel,
        onPressed: () => setState(_selected.clear),
      ),
      title: Text(context.l10n.selected_count(_selected.length)),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.listChecks),
          tooltip: context.l10n.select_all,
          onPressed: () => _selectAll(all),
        ),
        IconButton(
          icon: Icon(LucideIcons.trash2, color: context.tokens.danger),
          tooltip: context.l10n.delete,
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitId = widget.habitId;
    final sessions = context
        .watch<FocusController>()
        .sessions
        .where((s) => habitId == null || s.habitId == habitId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final days = <String, List<FocusSession>>{};
    for (final session in sessions) {
      days.putIfAbsent(session.startedAt.dayKey, () => []).add(session);
    }

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: _appBar(context, sessions),
        body: sessions.isEmpty
            ? AppEmptyState(
                icon: LucideIcons.history,
                title: context.l10n.focus_history_empty,
                message: context.l10n.focus_history_empty_sub,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  for (final (index, day) in days.entries.indexed)
                    Entrance(
                      index: index,
                      delay: _entrance,
                      child: Column(
                        children: [
                          _DayHeader(
                            day: parseDayKey(day.key),
                            sessions: day.value.length,
                            seconds:
                                day.value.fold(0, (sum, s) => sum + s.seconds),
                          ),
                          for (final session in day.value)
                            _SessionTile(
                              session: session,
                              selected: _selected.contains(session.id),
                              selecting: _selecting,
                              onToggle: () => _toggle(session.id),
                            ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.sessions,
    required this.seconds,
  });

  final DateTime day;
  final int sessions;
  final int seconds;

  String _label(BuildContext context) {
    final today = DateTime.now();
    if (day.isSameDay(today)) return context.l10n.today;
    if (day.isSameDay(today.subtract(const Duration(days: 1)))) {
      return context.l10n.yesterday;
    }
    final locale = Localizations.localeOf(context).toString();
    final pattern = day.year == today.year ? 'EEEE, d MMM' : 'd MMM yyyy';
    return DateFormat(pattern, locale).format(day);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label(context),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
          ),
          Text(
            '${context.l10n.focus_history_day(sessions)}  ·  '
            '${formatHoursShort(seconds)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.selecting,
    required this.onToggle,
  });

  final FocusSession session;
  final bool selected;
  final bool selecting;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final habit = session.habitId.isEmpty
        ? null
        : context.watch<HabitsController>().byId(session.habitId);
    final color = habit?.color ?? context.colors.primary;
    final locale = Localizations.localeOf(context).toString();
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: selecting ? onToggle : null,
          onLongPress: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.16)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                  ),
                  child: Center(
                    child: selected
                        ? Icon(LucideIcons.check, size: 20, color: color)
                        : habit == null
                            ? Icon(LucideIcons.timer, size: 18, color: color)
                            : HabitGlyph(
                                glyph: habit.icon,
                                color: color,
                                size: 18,
                              ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit == null
                            ? context.l10n.focus_free_session
                            : habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat.Hm(locale).format(session.startedAt)}'
                        '  ·  '
                        '${context.l10n.minutes_short('${session.targetMinutes}')}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatHoursShort(session.seconds),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (session.completed) ...[
                      const SizedBox(height: 3),
                      Icon(
                        LucideIcons.circleCheck,
                        size: 14,
                        color: context.tokens.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
