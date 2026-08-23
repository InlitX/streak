import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/core/widgets/entrance.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/focus/widgets/focus_log_sheet.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

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

  Future<void> _log() async {
    final added = await showFocusLogSheet(context, habitId: widget.habitId);
    if (added != true || !mounted) return;
    AppSnackbar.success(context, context.l10n.focus_log_saved);
  }

  PreferredSizeWidget _appBar(BuildContext context, List<FocusSession> all) {
    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;
    if (!_selecting) {
      if (express) {
        return expressBar(
          actions: [
            Center(
              child: ExpressIconButton(
                icon: LucideIcons.plus,
                tooltip: context.l10n.focus_log,
                onPressed: _log,
              ),
            ),
          ],
        );
      }
      return AppBar(
        toolbarHeight: minimal ? 52 : null,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: minimal ? null : Text(_title(context)),
        actions: [
          IconButton(
            tooltip: context.l10n.focus_log,
            icon: const Icon(LucideIcons.plus),
            onPressed: _log,
          ),
        ],
      );
    }
    return AppBar(
      toolbarHeight: express ? 60 : null,
      leadingWidth: express ? 68 : null,
      leading: express
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: ExpressIconButton(
                  icon: LucideIcons.x,
                  tooltip: context.l10n.cancel,
                  onPressed: () => setState(_selected.clear),
                ),
              ),
            )
          : IconButton(
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
    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;
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
                padding: express
                    ? context.pagePadding(18, 0, 18, 28)
                    : minimal
                    ? context.pagePadding(20, 0, 20, 28)
                    : context.pagePadding(16, 8, 16, 28),
                children: [
                  if (express)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ExpressHeadline(title: _title(context)),
                    ),
                  if (minimal) MinimalTitle(title: _title(context)),
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
    final express = context.watch<SettingsController>().isExpressStyle;
    return Padding(
      padding: EdgeInsets.fromLTRB(express ? 6 : 4, 12, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: express
                  ? ExpressType.headline.at(
                      15,
                      weight: 800,
                      color: context.colors.primary,
                    )
                  : TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                    ),
            ),
          ),
          Text(
            '${context.l10n.focus_history_day(sessions)}  ·  '
            '${formatHoursShort(seconds)}',
            style: express
                ? ExpressType.body.at(
                    12,
                    weight: 700,
                    color: context.tokens.muted,
                  )
                : TextStyle(
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
    final express = context.watch<SettingsController>().isExpressStyle;

    return Padding(
      padding: EdgeInsets.only(bottom: express ? 6 : 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: selecting ? onToggle : null,
          onLongPress: onToggle,
          child: AnimatedContainer(
            duration: express
                ? Express.normal
                : const Duration(milliseconds: 180),
            curve: express ? Express.emphasized : Curves.linear,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.16)
                  : express
                      ? expressSurface(context)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(
                express ? (selected ? 26 : 22) : 16,
              ),
              border: selected
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : express
                      ? expressHairline(context)
                      : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                if (express)
                  ExpressBlob(
                    size: 40,
                    color: color.withValues(alpha: selected ? 0.24 : 0.14),
                    shape: session.completed
                        ? ExpressShape.cookie.copyWith(rotation: 0.2)
                        : ExpressShape.squircle,
                    child: selected
                        ? Icon(LucideIcons.check, size: 19, color: color)
                        : habit == null
                            ? Icon(LucideIcons.timer, size: 18, color: color)
                            : HabitGlyph(
                                glyph: habit.icon,
                                color: color,
                                size: 18,
                              ),
                  )
                else
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
                        style: express
                            ? ExpressType.headline.at(
                                15.5,
                                weight: 800,
                                color: scheme.onSurface,
                              )
                            : TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat.Hm(locale).format(session.startedAt)}'
                        '  ·  '
                        '${session.targetMinutes <= 0 ? context.l10n.focus_flowtime : context.l10n.minutes_short('${session.targetMinutes}')}',
                        style: express
                            ? ExpressType.body.at(
                                12,
                                weight: 600,
                                color: context.tokens.muted,
                              )
                            : TextStyle(
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
                      style: express
                          ? ExpressType.display.at(
                              17,
                              spacing: -0.3,
                              color: color,
                              tabular: true,
                            )
                          : TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: color,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
