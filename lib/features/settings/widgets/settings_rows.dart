import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/utils/responsive.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';

Widget settingsDivider(BuildContext context) => Divider(
      height: 1,
      indent: bareRows(context) ? 16 : 60,
      endIndent: 16,
      color: context.colors.surfaceContainerHighest,
    );

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.tint});

  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? context.colors.onSurface;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: tint == null
            ? context.colors.surfaceContainerHighest
            : tint!.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _row(context, box.maxWidth));

  Widget _row(BuildContext context, double width) {
    final stacked = stackedRows(context);
    final inner = width - 32;
    final segmented = trailing is Segmented ? trailing as Segmented : null;
    final longest = _longestWord(context);
    final heading = textWidth(context, title, _titleStyle);
    final compact = segmented != null &&
        (stacked
            ? segmented.naturalWidth(context) > inner - 44
            : inner - 56 - segmented.naturalWidth(context) <
                (heading > 100 ? heading : 100));
    final shown = compact
        ? SegmentedSelect(segmented: segmented, title: title)
        : trailing;
    final side = stacked
        ? 0.0
        : compact
            ? SegmentedSelect.width
            : segmented?.naturalWidth(context) ?? 64;
    final bare = bareRows(context) ||
        longest > inner - 44 - (stacked ? 0 : side + 12);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!bare) IconBadge(icon: icon),
          if (!bare) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: context.tokens.muted),
                  ),
                ],
                if (stacked) ...[
                  const SizedBox(height: 10),
                  shown,
                ],
              ],
            ),
          ),
          if (!stacked) const SizedBox(width: 12),
          if (!stacked) shown,
        ],
      ),
    );
    if (enabled) return row;
    return IgnorePointer(child: Opacity(opacity: 0.45, child: row));
  }

  static const _titleStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  double _longestWord(BuildContext context) {
    var longest = 0.0;
    for (final word in title.split(' ')) {
      final width = textWidth(context, word, _titleStyle);
      if (width > longest) longest = width;
    }
    return longest;
  }
}

double textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return painter.width;
}

class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.badge,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback onTap;
  final String? badge;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final stacked = stackedValue(context, value);
    final shown = value == null
        ? null
        : Text(
            value!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.tokens.muted,
            ),
          );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: bareRows(context) ? null : IconBadge(icon: icon, tint: tint),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            TagPill(label: badge!),
          ],
        ],
      ),
      subtitle: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(color: context.tokens.muted)),
                const SizedBox(height: 4),
                shown!,
              ],
            )
          : subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: context.tokens.muted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!stacked && shown != null) shown,
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight,
              size: 18, color: context.tokens.muted),
        ],
      ),
      onTap: onTap,
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: bareRows(context) ? null : IconBadge(icon: icon),
      horizontalTitleGap: 14,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: context.tokens.muted)),
      trailing:
          Icon(LucideIcons.chevronRight, size: 18, color: context.tokens.muted),
      onTap: onTap,
    );
  }
}

class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final stacked = stackedRows(context);
    final bare = bareRows(context);
    final shown = value == null
        ? null
        : Text(
            value!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.tokens.muted,
            ),
          );
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (!bare) IconBadge(icon: icon),
              if (!bare) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.tokens.muted,
                        ),
                      ),
                    ],
                    if (stacked && shown != null) ...[
                      const SizedBox(height: 4),
                      shown,
                    ],
                  ],
                ),
              ),
              if (!stacked && shown != null) ...[
                const SizedBox(width: 12),
                shown,
              ],
              if (trailing != null) trailing!,
              const SizedBox(width: 6),
              Icon(LucideIcons.chevronRight,
                  size: 18, color: context.tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
  });

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  static const _label = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

  double naturalWidth(BuildContext context) {
    var total = 5.0;
    for (final option in options) {
      total += textWidth(context, option, _label) + 18;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            Semantics(
              button: true,
              selected: i == index,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: i == index ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    options[i],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == index ? scheme.onPrimary : context.tokens.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SegmentedSelect extends StatelessWidget {
  const SegmentedSelect({
    super.key,
    required this.segmented,
    required this.title,
  });

  static const width = 140.0;

  final Segmented segmented;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => showOptionSheet(
          context,
          title: title,
          options: segmented.options,
          index: segmented.index,
          onSelected: segmented.onChanged,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: width),
          padding: const EdgeInsets.fromLTRB(12, 7, 9, 7),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  segmented.options[segmented.index.clamp(0, segmented.options.length - 1)],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronsUpDown, size: 15, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
