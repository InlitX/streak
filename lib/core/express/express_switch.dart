import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';

class ExpressSwitch extends StatelessWidget {
  const ExpressSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.tint,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = tint ?? scheme.primary;

    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: Express.quick,
          curve: Express.emphasized,
          width: 56,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: value
                ? accent
                : context.tokens.muted.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(17),
          ),
          child: AnimatedAlign(
            duration: Express.normal,
            curve: Express.bouncy,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: Express.normal,
              curve: Express.bouncy,
              width: value ? 26 : 20,
              height: value ? 26 : 20,
              decoration: ShapeDecoration(
                color: value ? Colors.white : scheme.surface,
                shape: ExpressBorder(
                  shape: value
                      ? ExpressShape.cookie.copyWith(rotation: 0.35)
                      : ExpressShape.circle,
                ),
              ),
              child: value
                  ? Icon(LucideIcons.check, size: 14, color: accent)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
