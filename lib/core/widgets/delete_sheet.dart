import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';

Future<bool> showDeleteSheet(BuildContext context) async {
  HapticFeedback.mediumImpact();
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ListTile(
        leading: Icon(LucideIcons.trash2, color: sheetContext.tokens.danger),
        title: Text(
          sheetContext.l10n.delete,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: sheetContext.tokens.danger,
          ),
        ),
        onTap: () => Navigator.of(sheetContext).pop(true),
      ),
    ),
  );
  return confirmed ?? false;
}
