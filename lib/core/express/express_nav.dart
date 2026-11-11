import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/express/express_shapes.dart';

class ExpressNavItem {
  const ExpressNavItem({
    required this.icon,
    required this.label,
    this.iconOnly = false,
  });

  final IconData icon;
  final String label;
  final bool iconOnly;
}

class ExpressNavBar extends StatelessWidget {
  const ExpressNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
  });

  final List<ExpressNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: dark ? 0.22 : 0.16),
          dark ? scheme.surface : Colors.white,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.42 : 0.14),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final labeled = index >= 0 &&
              index < items.length &&
              !items[index].iconOnly &&
              _widthWithLabel(context, items[index].label) <= box.maxWidth;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavPill(
                  item: items[i],
                  selected: i == index,
                  labeled: labeled,
                  onTap: () => onSelect(i),
                ),
            ],
          );
        },
      ),
    );
  }

  double _widthWithLabel(BuildContext context, String label) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: ExpressType.headline.at(14, weight: 800),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final shown = text.width.clamp(0.0, 92.0);
    return items.length * 51 + 6 + 9 + shown;
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.selected,
    required this.labeled,
    required this.onTap,
  });

  final ExpressNavItem item;
  final bool selected;
  final bool labeled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tint = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onTap();
        },
        child: AnimatedContainer(
          duration: Express.normal,
          curve: Express.bouncy,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: selected && labeled ? 18 : 15),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: Express.normal,
                curve: Express.bouncy,
                child: Icon(item.icon, size: 21, color: tint),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: Express.normal,
                  curve: Express.emphasized,
                  child: selected && labeled
                      ? Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 92),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: ExpressType.headline.at(
                                14,
                                weight: 800,
                                color: tint,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpressNavRail extends StatelessWidget {
  const ExpressNavRail({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.brand,
    this.compact = false,
  });

  static const width = 224.0;

  final List<ExpressNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget brand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 80 : width,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 24, compact ? 12 : 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              brand,
              const SizedBox(height: 28),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RailPill(
                    item: items[i],
                    selected: i == index,
                    compact: compact,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPill extends StatefulWidget {
  const _RailPill({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final ExpressNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_RailPill> createState() => _RailPillState();
}

class _RailPillState extends State<_RailPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selected = widget.selected;
    final scheme = context.colors;
    final tint = selected ? scheme.onPrimary : context.tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: Express.normal,
          curve: Express.bouncy,
          padding: EdgeInsets.all(widget.compact ? 8 : 12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.primary.withValues(alpha: _hover ? 0.16 : 0.06),
            borderRadius: BorderRadius.circular(selected ? 24 : 14),
          ),
          child: Tooltip(
            message: widget.compact ? item.label : '',
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Express.normal,
                curve: Express.bouncy,
                width: 30,
                height: 30,
                decoration: ShapeDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.transparent,
                  shape: ExpressBorder(
                    shape: selected
                        ? ExpressShape.cookie
                        : ExpressShape.squircle,
                  ),
                ),
                child: Icon(item.icon, size: 17, color: tint),
              ),
              if (!widget.compact) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.headline.at(14, weight: 800, color: tint),
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
        ),
      ),
    );
  }
}
