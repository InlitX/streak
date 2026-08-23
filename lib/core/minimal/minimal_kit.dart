import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/minimal/minimal_type.dart';

Widget minimalBody({required String title, required Widget child}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: MinimalTitle(title: title),
    ),
    Expanded(child: child),
  ],
);

Color minimalSurface(BuildContext context) =>
    context.colors.surfaceContainer;

Color minimalRaised(BuildContext context) =>
    context.colors.surfaceContainerHighest;

Color minimalLineColor(BuildContext context) =>
    context.tokens.muted.withValues(alpha: 0.16);

class MinimalPress extends StatefulWidget {
  const MinimalPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.978,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<MinimalPress> createState() => _MinimalPressState();
}

class _MinimalPressState extends State<MinimalPress> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class MinimalSwap extends StatelessWidget {
  const MinimalSwap({super.key, required this.child, this.alignment});

  final Widget child;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment ?? Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.28),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class MinimalCard extends StatelessWidget {
  const MinimalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: minimalSurface(context),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return body;
    return MinimalPress(
      onTap: onTap,
      onLongPress: onLongPress,
      child: body,
    );
  }
}

class MinimalTitle extends StatelessWidget {
  const MinimalTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MinimalType.display(33, color: context.colors.onSurface),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.tokens.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MinimalHeading extends StatelessWidget {
  const MinimalHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MinimalType.title(
                    17,
                    weight: 700,
                    color: context.colors.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MinimalType.label(color: context.tokens.muted),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class MinimalSection extends StatelessWidget {
  const MinimalSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.gap = 26,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MinimalHeading(title: title, subtitle: subtitle, trailing: trailing),
          child,
        ],
      ),
    );
  }
}

class MinimalTile extends StatelessWidget {
  const MinimalTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.tint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    return MinimalCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MinimalType.label(color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MinimalSwap(
            child: FittedBox(
              key: ValueKey(value),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: MinimalType.figure(
                  27,
                  color: tint ?? context.colors.onSurface,
                ),
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 5),
            MinimalSwap(
              child: Text(
                caption!,
                key: ValueKey(caption),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MinimalType.label(color: muted, size: 11.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MinimalGrid extends StatelessWidget {
  const MinimalGrid({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(SizedBox(height: spacing));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class MinimalRow extends StatelessWidget {
  const MinimalRow({
    super.key,
    required this.label,
    this.value,
    this.caption,
    this.leading,
    this.trailing,
    this.onTap,
    this.tint,
    this.last = false,
  });

  final String label;
  final String? value;
  final String? caption;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tint;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MinimalType.body(
                    14.5,
                    weight: 500,
                    color: value == null && tint != null
                        ? tint
                        : context.colors.onSurface,
                  ),
                ),
                if (caption != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MinimalType.label(color: muted, size: 11.5),
                    ),
                  ),
              ],
            ),
          ),
          if (value != null)
            MinimalSwap(
              alignment: Alignment.centerRight,
              child: Text(
                value!,
                key: ValueKey(value),
                style: MinimalType.figure(
                  16,
                  color: tint ?? context.colors.onSurface,
                ),
              ),
            ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: muted.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onTap == null) row else MinimalPress(onTap: onTap, child: row),
        if (!last)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(height: 1, color: minimalLineColor(context)),
          ),
      ],
    );
  }
}

class MinimalList extends StatelessWidget {
  const MinimalList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: minimalSurface(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class MinimalButton extends StatelessWidget {
  const MinimalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: scheme.onSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: scheme.surface),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MinimalType.title(
                      15.5,
                      weight: 700,
                      color: scheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MinimalSegmented extends StatelessWidget {
  const MinimalSegmented({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
    this.expand = false,
    this.enabled = true,
  });

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;
  final bool expand;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: minimalRaised(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: expand
              ? LayoutBuilder(
                  builder: (context, box) => _track(
                    context,
                    scheme,
                    box.maxWidth / options.length,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < options.length; i++)
                      _cell(context, scheme, i),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _track(BuildContext context, ColorScheme scheme, double cell) {
    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: cell * index,
            width: cell,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.onSurface,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < options.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled ? () => onChanged(i) : null,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: DefaultTextStyle.of(context).style.merge(
                              MinimalType.label(
                                size: 13,
                                color: i == index
                                    ? scheme.surface
                                    : context.tokens.muted,
                              ),
                            ),
                        child: Text(
                          options[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, ColorScheme scheme, int i) {
    final cell = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged(i) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: i == index ? scheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          options[i],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: MinimalType.label(
            size: 13,
            color: i == index ? scheme.surface : context.tokens.muted,
          ),
        ),
      ),
    );
    return expand ? Expanded(child: cell) : cell;
  }
}

class MinimalChips extends StatelessWidget {
  const MinimalChips({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class MinimalChip extends StatelessWidget {
  const MinimalChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.tint,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? scheme.onSurface : minimalRaised(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tint != null && !active) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MinimalType.label(
                  size: 13,
                  color: active ? scheme.surface : context.tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
