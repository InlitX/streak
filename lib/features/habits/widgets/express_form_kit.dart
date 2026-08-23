import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/icons/habit_glyph.dart';
import 'package:streak/core/widgets/cover_image.dart';
import 'package:streak/features/habits/data/habit.dart';

class ExpressFormHero extends StatelessWidget {
  const ExpressFormHero({
    super.key,
    required this.icon,
    required this.color,
    required this.controller,
    required this.onChanged,
    required this.onShuffleIcon,
    this.cover = '',
  });

  final String icon;
  final Color color;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onShuffleIcon;
  final String cover;

  @override
  Widget build(BuildContext context) {
    final empty = controller.text.trim().isEmpty;
    final hasCover = CoverImage.exists(cover);
    final onHero = hasCover ? Colors.white : context.colors.onSurface;
    final subtle = hasCover
        ? Colors.white.withValues(alpha: 0.7)
        : context.tokens.muted.withValues(alpha: 0.55);

    return ExpressCard(
      radius: Express.heroRadius,
      padding: EdgeInsets.zero,
      clip: true,
      child: Stack(
        children: [
          if (hasCover) ...[
            Positioned.fill(child: CoverImage(path: cover)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.62),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Column(
              children: [
                Semantics(
                  button: true,
                  label: context.l10n.icon,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onShuffleIcon();
                    },
                    child: AnimatedContainer(
                      duration: Express.morph,
                      curve: Express.bouncy,
                      width: 92,
                      height: 92,
                      decoration: ShapeDecoration(
                        color: hasCover
                            ? color.withValues(alpha: 0.55)
                            : color.withValues(alpha: 0.18),
                        shape: ExpressBorder(
                          shape: ExpressShape.cookie.copyWith(
                            rotation: empty ? 0 : 0.24,
                          ),
                        ),
                      ),
                      child: HabitGlyph(
                        glyph: icon,
                        color: hasCover ? Colors.white : color,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                  cursorColor: color,
                  style: ExpressType.display.at(
                    28,
                    height: 1.15,
                    spacing: -0.3,
                    color: onHero,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: context.l10n.name_hint,
                    hintStyle: ExpressType.display.at(
                      28,
                      height: 1.15,
                      weight: 700,
                      color: subtle,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: Express.normal,
                  curve: Express.emphasized,
                  height: 5,
                  width: empty ? 44 : 96,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpressKindPills extends StatelessWidget {
  const ExpressKindPills({
    super.key,
    required this.kind,
    required this.locked,
    required this.onChanged,
  });

  final HabitKind kind;
  final bool locked;
  final ValueChanged<HabitKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (HabitKind.positive, LucideIcons.circleCheck, context.l10n.kind_positive),
      (HabitKind.negative, LucideIcons.ban, context.l10n.kind_negative),
      (
        HabitKind.quantitative,
        LucideIcons.gauge,
        context.l10n.kind_quantitative,
      ),
    ];

    return Row(
      children: [
        for (final option in options) ...[
          if (option.$1 != HabitKind.positive)
            const SizedBox(width: Express.groupGap),
          Expanded(
            child: _KindPill(
              icon: option.$2,
              label: option.$3,
              selected: option.$1 == kind,
              dimmed: locked && option.$1 != kind,
              onTap: locked ? null : () => onChanged(option.$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final ink = selected
        ? scheme.onPrimary
        : dimmed
        ? context.tokens.muted.withValues(alpha: 0.5)
        : context.tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      child: ExpressSquish(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Express.morph,
          curve: Express.bouncy,
          height: 84,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : expressSurface(context),
            borderRadius: BorderRadius.circular(selected ? 30 : 16),
            border: selected ? null : expressHairline(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: ink),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ExpressType.headline.at(
                  12.5,
                  weight: selected ? 800 : 700,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpressSaveBar extends StatelessWidget {
  const ExpressSaveBar({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: ExpressSquish(
        onTap: onPressed,
        scale: 0.95,
        child: AnimatedContainer(
          duration: Express.quick,
          curve: Express.emphasized,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 34),
          decoration: BoxDecoration(
            color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(31),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.check,
                size: 21,
                color: enabled ? scheme.onPrimary : context.tokens.muted,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: ExpressType.headline.at(
                  16.5,
                  weight: 800,
                  color: enabled ? scheme.onPrimary : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
