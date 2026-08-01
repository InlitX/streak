import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/features/focus/data/focus_session.dart';
import 'package:streak/features/focus/pages/focus_page.dart';
import 'package:streak/features/focus/pages/focus_setup_page.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class FocusPill extends StatelessWidget {
  const FocusPill({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SettingsController>().focusEnabled) {
      return const SizedBox.shrink();
    }

    final focus = context.watch<FocusController>();
    final active = focus.isActive;
    final accent = context.colors.primary;

    void open() => active
        ? AppNavigator.push(const FocusPage(), fade: true)
        : AppNavigator.push(const FocusSetupPage(), fullscreenDialog: true);

    if (compact && !active) {
      return IconButton(
        onPressed: open,
        icon: Icon(LucideIcons.timer, size: 22, color: context.colors.onSurface),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: open,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.16)
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: active
                ? Border.all(color: accent.withValues(alpha: 0.6))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.timer,
                size: 17,
                color: active ? accent : context.tokens.muted,
              ),
              const SizedBox(width: 6),
              Text(
                active
                    ? formatDuration(focus.remainingSeconds)
                    : context.l10n.focus,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? accent : context.tokens.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
