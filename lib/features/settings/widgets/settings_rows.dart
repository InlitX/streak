import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';

Widget settingsDivider(BuildContext context) => Divider(
      height: 1,
      indent: 60,
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
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: icon),
          const SizedBox(width: 14),
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
    if (enabled) return row;
    return IgnorePointer(child: Opacity(opacity: 0.45, child: row));
  }
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: IconBadge(icon: icon, tint: tint),
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
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: context.tokens.muted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.tokens.muted,
              ),
            ),
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
      leading: IconBadge(icon: icon),
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
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconBadge(icon: icon),
              const SizedBox(width: 14),
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
                  ],
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.tokens.muted,
                  ),
                ),
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
