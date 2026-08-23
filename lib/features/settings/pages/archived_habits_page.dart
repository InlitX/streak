import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_empty_state.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/habits/state/notes_controller.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class ArchivedHabitsPage extends StatelessWidget {
  const ArchivedHabitsPage({super.key});

  Future<void> _deleteForever(BuildContext context, Habit habit) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.l10n.delete_forever,
      message: context.l10n.delete_forever_body(habit.name),
      confirmLabel: context.l10n.delete,
    );
    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();
    context.read<HabitsController>().remove(habit.id);
    context.read<NotesController>().reload();
    context.read<FocusController>().reload();
    if (context.mounted) {
      AppSnackbar.success(context, context.l10n.deleted_forever);
    }
  }

  @override
  Widget build(BuildContext context) {
    final archived = context.watch<HabitsController>().archived;
    final locale = Localizations.localeOf(context).toString();

    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;
    final body = archived.isEmpty
          ? AppEmptyState(
              icon: LucideIcons.archive,
              title: context.l10n.archived_empty,
              message: context.l10n.archived_empty_sub,
            )
          : ListView.separated(
              padding: context.pagePadding(16, 12, 16, 28),
              itemCount: archived.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final habit = archived[index];
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: express
                        ? expressSurface(context)
                        : context.colors.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(express ? 24 : 18),
                    border: express ? expressHairline(context) : null,
                  ),
                  child: Row(
                    children: [
                      if (express)
                        ExpressBlob(
                          size: 42,
                          color: habit.color.withValues(alpha: 0.16),
                          shape: ExpressShape.squircle,
                          child: HabitGlyph(
                            glyph: habit.icon,
                            color: habit.color,
                            size: 19,
                          ),
                        )
                      else
                        Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: habit.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: HabitGlyph(
                          glyph: habit.icon,
                          color: habit.color,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: express
                                  ? ExpressType.headline.at(
                                      15.5,
                                      weight: 800,
                                      color: context.colors.onSurface,
                                    )
                                  : TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.onSurface,
                                    ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat.yMMMd(locale).format(habit.archivedAt!),
                              style: express
                                  ? ExpressType.body.at(
                                      12.5,
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
                      IconButton(
                        tooltip: context.l10n.restore,
                        icon: Icon(
                          LucideIcons.rotateCcw,
                          size: 19,
                          color: context.colors.primary,
                        ),
                        onPressed: () {
                          context.read<HabitsController>().restore(habit.id);
                          AppSnackbar.success(context, context.l10n.restored);
                        },
                      ),
                      IconButton(
                        tooltip: context.l10n.delete_forever,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 19,
                          color: context.tokens.danger,
                        ),
                        onPressed: () => _deleteForever(context, habit),
                      ),
                    ],
                  ),
                );
              },
            );

    return Scaffold(
      appBar: express
          ? expressBar()
          : AppBar(
              toolbarHeight: minimal ? 52 : null,
              leading: IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: () => AppNavigator.pop(),
              ),
              title: minimal ? null : Text(context.l10n.archived_habits),
            ),
      body: express
          ? expressBody(title: context.l10n.archived_habits, child: body)
          : minimal
          ? minimalBody(title: context.l10n.archived_habits, child: body)
          : body,
    );
  }
}
