import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';

Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  String? extraLabel,
  VoidCallback? onExtra,
  Widget? body,
  IconData icon = LucideIcons.trash2,
  bool danger = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = dialogContext.colors;
      final accent = danger ? dialogContext.tokens.danger : scheme.primary;
      return Dialog(
        backgroundColor: scheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: sheetTitleStyle(dialogContext, size: 19),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: sheetBodyStyle(dialogContext, size: 14),
              ),
              if (body != null) ...[
                const SizedBox(height: 16),
                body,
              ],
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, box) {
                  final cancelText = cancelLabel ?? dialogContext.l10n.cancel;
                  double wide(String text) => (TextPainter(
                        text: TextSpan(
                          text: text,
                          style: sheetActionStyle(dialogContext),
                        ),
                        maxLines: 1,
                        textDirection: Directionality.of(dialogContext),
                        textScaler: MediaQuery.textScalerOf(dialogContext),
                      )..layout())
                          .width;
                  final stacked = wide(cancelText) > (box.maxWidth - 12) / 2 - 24 ||
                      wide(confirmLabel) > (box.maxWidth - 12) / 2 - 24;
                  final cancel = TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      backgroundColor: scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      textAlign: TextAlign.center,
                      style: sheetActionStyle(
                        dialogContext,
                        color: scheme.onSurface,
                      ),
                    ),
                  );
                  final confirm = FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: accent.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      textAlign: TextAlign.center,
                      style: sheetActionStyle(dialogContext),
                    ),
                  );
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [confirm, const SizedBox(height: 10), cancel],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: 12),
                      Expanded(child: confirm),
                    ],
                  );
                },
              ),
              if (extraLabel != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                    onExtra?.call();
                  },
                  child: Text(
                    extraLabel,
                    style: sheetActionStyle(
                      dialogContext,
                      size: 14,
                      color: dialogContext.tokens.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
