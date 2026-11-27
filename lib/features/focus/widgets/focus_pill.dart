import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/pages/focus_setup_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/todos/state/todos_controller.dart';
import 'package:streak/core/widgets/glass.dart';

class FocusPill extends StatelessWidget {
  const FocusPill({
    super.key,
    this.compact = false,
    this.dense = false,
    this.glass = false,
  });

  final bool compact;
  final bool dense;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SettingsController>().focusEnabled) {
      return const SizedBox.shrink();
    }

    final focus = context.watch<FocusController>();
    final active = focus.isActive;
    final accent = context.colors.primary;

    void open() => openFocus(context);

    if (glass) {
      final ink = active ? accent : context.colors.onSurface;
      return GlassPill(
        onTap: open,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.timer, size: 16, color: ink),
            const SizedBox(width: 6),
            Text(
              active ? formatDuration(focus.displaySeconds) : context.l10n.focus,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    if (compact && !active) {
      return IconButton(
        onPressed: open,
        icon: Icon(LucideIcons.timer, size: 22, color: context.colors.onSurface),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: open,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 9 : 12,
              vertical: dense ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: 0.16)
                  : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(color: accent.withValues(alpha: 0.6))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.timer,
                  size: dense ? 15 : 16,
                  color: active ? accent : context.tokens.muted,
                ),
                SizedBox(width: dense ? 5 : 6),
                Text(
                  active
                      ? formatDuration(focus.displaySeconds)
                      : context.l10n.focus,
                  style: TextStyle(
                    fontSize: dense ? 12.5 : 13.5,
                    fontWeight: FontWeight.w700,
                    color: active ? accent : context.tokens.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void openFocus(BuildContext context) => context.read<FocusController>().isActive
    ? AppNavigator.push(
        const FocusPage(),
        fade: true,
        name: FocusPage.routeName,
      )
    : AppNavigator.push(const FocusSetupPage(), fullscreenDialog: true);

Future<void> pushFocus(BuildContext context, FocusPage start) async {
  final focus = context.read<FocusController>();
  if (focus.isActive) {
    final same = start.startTodoId.isNotEmpty
        ? focus.todoId == start.startTodoId
        : start.startHabitId == null ||
            (focus.todoId.isEmpty && focus.habitId == start.startHabitId);
    if (!same) {
      final name = context.read<TodosController>().byId(focus.todoId)?.title ??
          context.read<HabitsController>().byId(focus.habitId)?.name ??
          (focus.label.isEmpty ? context.l10n.focus_free_session : focus.label);
      final open = await showAppConfirmDialog(
        context,
        title: context.l10n.focus_busy_title,
        message: context.l10n.focus_busy_body(name),
        confirmLabel: context.l10n.focus_busy_open,
        icon: LucideIcons.timer,
        danger: false,
      );
      if (open != true || !context.mounted) return;
    }
  }
  await AppNavigator.push(
    focus.isActive ? const FocusPage() : start,
    fade: true,
    name: FocusPage.routeName,
  );
}
