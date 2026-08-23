import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';

Future<bool> showDeleteSheet(BuildContext context) async {
  HapticFeedback.mediumImpact();
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ListTile(
        leading: Icon(LucideIcons.trash2, color: sheetContext.tokens.danger),
        title: Text(
          sheetContext.l10n.delete,
          style: sheetOptionStyle(
            sheetContext,
            selected: true,
            color: sheetContext.tokens.danger,
          ),
        ),
        onTap: () => Navigator.of(sheetContext).pop(true),
      ),
    ),
  );
  return confirmed ?? false;
}
