import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';

class MinimalPage extends StatelessWidget {
  const MinimalPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 52, leading: leading),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
          children: [
            MinimalTitle(title: title, subtitle: subtitle),
            ...children,
          ],
        ),
      ),
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
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 38,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.8,
              color: context.colors.onSurface,
            ),
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

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? context.colors.surfaceContainerHighest.withValues(alpha: 0.38)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: context.tokens.muted.withValues(alpha: isDark ? 0.14 : 0.10),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class SoftRow extends StatelessWidget {
  const SoftRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.tokens.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashFactory: NoSplash.splashFactory,
      highlightColor: context.tokens.muted.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 19, color: muted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: trailing!,
              ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: muted.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required int index,
  required ValueChanged<int> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < options.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  onSelected(i);
                  Navigator.of(sheet).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                i == index ? FontWeight.w700 : FontWeight.w500,
                            color: i == index
                                ? context.colors.primary
                                : context.colors.onSurface,
                          ),
                        ),
                      ),
                      if (i == index)
                        Icon(LucideIcons.check,
                            size: 18, color: context.colors.primary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
