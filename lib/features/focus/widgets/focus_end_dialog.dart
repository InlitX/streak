import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';

class FocusEndDialog extends StatelessWidget {
  const FocusEndDialog({
    super.key,
    required this.reached,
    required this.lines,
    required this.accent,
  });

  final bool reached;
  final List<String> lines;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = reached ? context.tokens.success : accent;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              child: Icon(
                reached ? LucideIcons.partyPopper : LucideIcons.hourglass,
                size: 26,
                color: color,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.focus_stop_title,
              textAlign: TextAlign.center,
              style: sheetTitleStyle(context, size: 19),
            ),
            const SizedBox(height: 10),
            Text(
              lines.join('\n'),
              textAlign: TextAlign.center,
              style: sheetBodyStyle(context, size: 14),
            ),
            const SizedBox(height: 24),
            if (!reached) ...[
              _FocusDialogButton(
                icon: LucideIcons.circleCheck,
                label: context.l10n.focus_end_complete,
                background: color,
                foreground: color.computeLuminance() > 0.6
                    ? Colors.black
                    : Colors.white,
                onTap: () => Navigator.of(context).pop('done'),
              ),
              const SizedBox(height: 10),
            ],
            _FocusDialogButton(
              icon: LucideIcons.square,
              label:
                  reached ? context.l10n.focus_end : context.l10n.focus_end_anyway,
              background: reached
                  ? color
                  : context.colors.surfaceContainerHighest,
              foreground: reached
                  ? (color.computeLuminance() > 0.6
                      ? Colors.black
                      : Colors.white)
                  : context.colors.onSurface,
              onTap: () => Navigator.of(context).pop('end'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.focus_end_keep,
                style: sheetActionStyle(context, color: context.tokens.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusDialogButton extends StatelessWidget {
  const _FocusDialogButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: sheetActionStyle(context)),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
