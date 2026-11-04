import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/core/widgets/sheet_type.dart';

class LockMark extends StatelessWidget {
  const LockMark({super.key, required this.icon, this.size = 76});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.12),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, size: size * 0.42, color: tone),
    );
  }
}

class LockSteps extends StatelessWidget {
  const LockSteps({super.key, required this.step, this.total = 3});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == step ? 22 : 8,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i <= step ? tone : context.tokens.muted.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}

class RecoveryCodeBlocks extends StatelessWidget {
  const RecoveryCodeBlocks({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final parts = code.split(' ');
    return Row(
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  parts[i],
                  style: sheetFigureStyle(context, size: 22).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> showLockMethodSheet(
  BuildContext context, {
  required int index,
  required ValueChanged<int> onSelected,
}) {
  final options = [
    (
      LucideIcons.fingerprint,
      context.l10n.app_lock_biometric,
      context.l10n.app_lock_biometric_sub,
    ),
    (LucideIcons.grid3x3, context.l10n.pin_lock, context.l10n.pin_lock_sub),
  ];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sheet.l10n.app_lock_method,
              textAlign: TextAlign.center,
              style: sheetTitleStyle(sheet),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _MethodCard(
                icon: options[i].$1,
                title: options[i].$2,
                body: options[i].$3,
                selected: i == index,
                onTap: () {
                  Navigator.of(sheet).pop();
                  onSelected(i);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.primary;
    final muted = context.tokens.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? tone.withValues(alpha: 0.1)
            : context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? tone.withValues(alpha: 0.55) : Colors.transparent,
            width: 1.4,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? tone.withValues(alpha: 0.16)
                        : context.colors.onSurface.withValues(alpha: 0.06),
                  ),
                  child: Icon(icon, size: 21, color: selected ? tone : muted),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: sheetHeadingStyle(context)),
                      const SizedBox(height: 3),
                      Text(body, style: sheetBodyStyle(context, size: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Icon(LucideIcons.circleCheck, size: 22, color: tone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
