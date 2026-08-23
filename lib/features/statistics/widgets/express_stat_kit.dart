import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_button.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_shapes.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/features/statistics/widgets/stat_kit.dart';

class ExpressStatTile extends StatelessWidget {
  const ExpressStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    this.big = false,
    this.onTap,
    this.shape = ExpressShape.cookie,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;
  final bool big;
  final VoidCallback? onTap;
  final ExpressShape shape;

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(big ? 20 : 16),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(big ? 30 : 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpressBlob(
              size: big ? 40 : 34,
              color: tint.withValues(alpha: 0.22),
              shape: shape,
              child: Icon(icon, size: big ? 19 : 16, color: tint),
            ),
            SizedBox(height: big ? 16 : 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedStatNumber(
                value: value,
                style: ExpressType.display.at(
                  big ? 40 : 28,
                  height: 1,
                  spacing: big ? -0.8 : -0.5,
                  color: context.colors.onSurface,
                  tabular: true,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ExpressType.body.at(
                big ? 13 : 12,
                height: 1.25,
                weight: 700,
                color: context.tokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpressStatRow extends StatelessWidget {
  const ExpressStatRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.onTap,
    this.shape = ExpressShape.cookie,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback? onTap;
  final ExpressShape shape;

  @override
  Widget build(BuildContext context) {
    final radius = ExpressSlot.of(
      context,
      BorderRadius.circular(Express.cardRadius),
    );

    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 20, 18),
        decoration: BoxDecoration(
          color: expressSurface(context),
          borderRadius: radius,
          border: expressHairline(context),
        ),
        child: Row(
          children: [
            ExpressBlob(
              size: 44,
              color: tint.withValues(alpha: 0.18),
              shape: shape,
              child: Icon(icon, size: 20, color: tint),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.body.at(
                      12.5,
                      weight: 700,
                      color: context.tokens.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedStatNumber(
                      value: value,
                      style: ExpressType.display.at(
                        26,
                        height: 1.1,
                        spacing: -0.4,
                        color: context.colors.onSurface,
                        tabular: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.tokens.muted,
              ),
          ],
        ),
      ),
    );
  }
}

class ExpressStatPanel extends StatelessWidget {
  const ExpressStatPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.tint,
    required this.child,
    this.trailing,
    this.shape = ExpressShape.cookie,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final Widget child;
  final Widget? trailing;
  final ExpressShape shape;

  @override
  Widget build(BuildContext context) {
    return ExpressCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExpressBlob(
                size: 36,
                color: tint.withValues(alpha: 0.18),
                shape: shape,
                child: Icon(icon, size: 17, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ExpressType.headline.at(
                    17,
                    height: 1.2,
                    weight: 800,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class ExpressYearNav extends StatelessWidget {
  const ExpressYearNav({
    super.key,
    required this.year,
    required this.canGoForward,
    required this.onChanged,
  });

  final int year;
  final bool canGoForward;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExpressIconButton(
          icon: LucideIcons.chevronLeft,
          size: 46,
          background: expressSurface(context, level: 2),
          onPressed: () => onChanged(-1),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.calendarDays,
                    size: 15,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$year',
                    style: ExpressType.headline.at(
                      16,
                      weight: 800,
                      color: scheme.primary,
                      tabular: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ExpressIconButton(
          icon: LucideIcons.chevronRight,
          size: 46,
          background: expressSurface(context, level: 2),
          onPressed: canGoForward ? () => onChanged(1) : null,
        ),
      ],
    );
  }
}

class ExpressLevelBar extends StatelessWidget {
  const ExpressLevelBar({
    super.key,
    required this.value,
    required this.color,
    this.stroke = 6,
  });

  final double value;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final track = context.tokens.muted.withValues(alpha: 0.26);
    return SizedBox(
      height: stroke,
      child: LayoutBuilder(
        builder: (context, box) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: Express.slow,
          curve: Express.emphasized,
          builder: (context, t, _) {
            final filled = (box.maxWidth - stroke - 6) * t;
            return Stack(
              children: [
                Positioned(
                  right: 0,
                  child: Container(
                    width: stroke,
                    height: stroke,
                    decoration: BoxDecoration(
                      color: t >= 1 ? color : track,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (t < 1)
                  Positioned(
                    left: filled + 6,
                    right: stroke + 6,
                    child: Container(
                      height: stroke,
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: BorderRadius.circular(stroke),
                      ),
                    ),
                  ),
                Container(
                  width: filled,
                  height: stroke,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(stroke),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ExpressRanking extends StatelessWidget {
  const ExpressRanking({super.key, required this.entries, this.format});

  final List<({String name, Color color, int count})> entries;
  final String Function(int value)? format;

  String _value(int count) => format?.call(count) ?? '$count';

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final max = entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final total = entries.fold<int>(0, (a, e) => a + e.count);

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entries[i].color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entries[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ExpressType.headline.at(
                          14.5,
                          weight: 750,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      total == 0
                          ? _value(entries[i].count)
                          : '${_value(entries[i].count)}  ·  '
                                '${(entries[i].count / total * 100).round()}%',
                      style: ExpressType.body.at(
                        13,
                        weight: 700,
                        color: context.tokens.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ExpressLevelBar(
                  value: max == 0 ? 0 : entries[i].count / max,
                  color: entries[i].color,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
