import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/desk_island/desk_island_kit.dart';
import 'package:streak/features/focus/state/focus_actions.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/services/focus_service.dart';

enum IslandCardKind { focus, perfect }

class IslandCardData {
  const IslandCardData({
    required this.kind,
    this.breakEnded = false,
    this.streak = 0,
  });

  final IslandCardKind kind;
  final bool breakEnded;
  final int streak;
}

Future<void> endFocusFromIsland(FocusController focus) async {
  if (!focus.isActive) return;
  if (focus.isPomodoro && focus.isBreak) {
    await focus.stop(completed: true);
    return;
  }
  await applyFocusAction(
    FocusAction(kind: FocusAction.stop, at: DateTime.now()),
  );
}

class IslandCard extends StatelessWidget {
  const IslandCard({
    super.key,
    required this.data,
    required this.accent,
    required this.onDone,
    required this.onOpen,
  });

  final IslandCardData data;
  final Color accent;
  final VoidCallback onDone;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final IconData icon;
    final Color color;
    final String title;
    final String body;
    final actions = <Widget>[];

    if (data.kind == IslandCardKind.perfect) {
      icon = LucideIcons.partyPopper;
      color = IslandKit.rest;
      title = l10n.all_done_today;
      body = '';
    } else {
      final focus = context.watch<FocusController>();
      icon = data.breakEnded ? LucideIcons.coffee : LucideIcons.circleCheck;
      color = data.breakEnded ? IslandKit.rest : accent;
      title = data.breakEnded ? l10n.focus_break_over : l10n.focus_done_title;
      body = data.breakEnded
          ? l10n.focus_notif_back
          : focus.isPomodoro
          ? l10n.focus_notif_break
          : l10n.focus_notif_body;
      if (focus.isActive && (focus.isAwaiting || focus.switchIn > 0)) {
        actions.add(
          IslandButton(
            label: focus.switchIn > 0
                ? '${l10n.focus_continue} · ${focus.switchIn}'
                : l10n.focus_continue,
            icon: LucideIcons.play,
            primary: true,
            compact: true,
            onTap: () {
              focus.continueNow();
              onDone();
            },
          ),
        );
      } else if (focus.isActive && focus.isFinished) {
        actions
          ..add(
            IslandButton(
              label: '+1 min',
              compact: true,
              onTap: () {
                focus.addMinute();
                onDone();
              },
            ),
          )
          ..add(const SizedBox(width: 6))
          ..add(
            IslandButton(
              label: l10n.focus_end,
              icon: LucideIcons.check,
              primary: true,
              compact: true,
              onTap: () {
                endFocusFromIsland(focus);
                onDone();
              },
            ),
          );
      }
    }

    final subtitle = data.kind == IslandCardKind.perfect
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.flame, size: 13, color: IslandKit.fire),
              const SizedBox(width: 4),
              Text(
                '${data.streak}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: IslandKit.muted,
                  fontFeatures: IslandKit.figures,
                ),
              ),
            ],
          )
        : Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: IslandKit.muted),
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 18, 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  subtitle,
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 10),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}
