import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_motion.dart';
import 'package:streak/core/express/express_type.dart';

Color expressSurface(BuildContext context, {double level = 1}) {
  final scheme = context.colors;
  return switch (level.round()) {
    <= 0 => scheme.surfaceContainerLowest,
    1 => scheme.surfaceContainer,
    2 => scheme.surfaceContainerHigh,
    _ => scheme.surfaceContainerHighest,
  };
}

Color expressHairlineColor(BuildContext context) =>
    context.colors.outlineVariant.withValues(alpha: 0.25);

Border expressHairline(BuildContext context) =>
    Border.all(color: expressHairlineColor(context));

BorderRadius expressSlotRadius(int index, int length) {
  const edge = Radius.circular(Express.groupEdge);
  const joint = Radius.circular(Express.groupJoint);
  final first = index == 0;
  final last = index == length - 1;
  return BorderRadius.only(
    topLeft: first ? edge : joint,
    topRight: first ? edge : joint,
    bottomLeft: last ? edge : joint,
    bottomRight: last ? edge : joint,
  );
}

class ExpressSquish extends StatefulWidget {
  const ExpressSquish({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.965,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<ExpressSquish> createState() => _ExpressSquishState();
}

class _ExpressSquishState extends State<ExpressSquish> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              HapticFeedback.heavyImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        scale: _down && enabled ? widget.scale : 1,
        duration: _down ? Express.fast : Express.quick,
        curve: _down ? Express.settle : Express.bouncy,
        child: widget.child,
      ),
    );
  }
}

class ExpressCard extends StatelessWidget {
  const ExpressCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Express.inset),
    this.radius = Express.cardRadius,
    this.color,
    this.onTap,
    this.onLongPress,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? expressSurface(context),
        borderRadius: BorderRadius.circular(radius),
        border: expressHairline(context),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null && onLongPress == null) return body;
    return ExpressSquish(onTap: onTap, onLongPress: onLongPress, child: body);
  }
}

class ExpressGroup extends StatelessWidget {
  const ExpressGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const edge = Radius.circular(Express.groupEdge);
    const joint = Radius.circular(Express.groupJoint);
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == children.length - 1 ? 0 : Express.groupGap,
            ),
            child: ExpressSlot(
              radius: BorderRadius.only(
                topLeft: i == 0 ? edge : joint,
                topRight: i == 0 ? edge : joint,
                bottomLeft: i == children.length - 1 ? edge : joint,
                bottomRight: i == children.length - 1 ? edge : joint,
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class ExpressSlot extends InheritedWidget {
  const ExpressSlot({super.key, required this.radius, required super.child});

  final BorderRadius radius;

  static BorderRadius of(BuildContext context, BorderRadius fallback) =>
      context.dependOnInheritedWidgetOfExactType<ExpressSlot>()?.radius ??
      fallback;

  @override
  bool updateShouldNotify(ExpressSlot old) => old.radius != radius;
}

class ExpressTile extends StatelessWidget {
  const ExpressTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.trailing,
    this.tint,
    this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final Widget? trailing;
  final Color? tint;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = tint ?? scheme.primary;
    final radius = ExpressSlot.of(context, BorderRadius.circular(20));

    return ExpressSquish(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: expressSurface(context),
          borderRadius: radius,
          border: expressHairline(context),
        ),
        padding: EdgeInsets.fromLTRB(16, dense ? 14 : 18, 20, dense ? 14 : 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.headline.at(
                      16,
                      weight: 800,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: ExpressType.body.at(
                          13,
                          height: 1.35,
                          color: context.tokens.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Flexible(
                flex: 0,
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ExpressType.headline.at(
                    14.5,
                    weight: 800,
                    color: accent,
                  ),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

class ExpressMiniStat extends StatelessWidget {
  const ExpressMiniStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: tint),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: ExpressType.display.at(
                    19,
                    height: 1,
                    spacing: -0.2,
                    color: context.colors.onSurface,
                    tabular: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: ExpressType.body.at(
            9.5,
            weight: 700,
            color: context.tokens.muted,
          ),
        ),
      ],
    );
  }
}

class ExpressMiniRow extends StatelessWidget {
  const ExpressMiniRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: expressHairlineColor(context),
            ),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class ExpressHeadline extends StatelessWidget {
  const ExpressHeadline({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ExpressType.display.at(
            38,
            height: 1.05,
            spacing: -0.6,
            color: context.colors.onSurface,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              subtitle!,
              style: ExpressType.body.at(
                14,
                height: 1.4,
                color: context.tokens.muted,
              ),
            ),
          ),
      ],
    );
  }
}
