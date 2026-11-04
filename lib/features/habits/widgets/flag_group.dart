import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/extensions/color_extensions.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class FlagGroup extends StatelessWidget {
  const FlagGroup({super.key, required this.children});

  final List<Widget> children;

  static bool inside(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FlagScope>() != null;

  @override
  Widget build(BuildContext context) {
    final line = context.colors.outlineVariant.withValues(alpha: 0.6);
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, indent: 62, color: line),
          children[i],
        ],
      ],
    );
    if (inside(context)) return rows;

    final scoped = _FlagScope(
      child: Material(type: MaterialType.transparency, child: rows),
    );
    final settings = context.watch<SettingsController>();
    if (settings.isExpressStyle) {
      return ExpressCard(padding: EdgeInsets.zero, clip: true, child: scoped);
    }
    if (settings.isMinimalStyle) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: MinimalCard(padding: EdgeInsets.zero, child: scoped),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: scoped,
    );
  }
}

class _FlagScope extends InheritedWidget {
  const _FlagScope({required super.child});

  @override
  bool updateShouldNotify(_FlagScope oldWidget) => false;
}

class FlagDetail extends StatelessWidget {
  const FlagDetail({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(62, 0, 14, 14),
        child: child,
      );
}

class HabitFlagToggle extends StatelessWidget {
  const HabitFlagToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.color,
    required this.onChanged,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!FlagGroup.inside(context)) return FlagGroup(children: [this]);
    final tone = color.shownIn(context);
    final muted = context.tokens.muted;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, compact ? 10 : 12, 8, compact ? 10 : 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? tone.withValues(alpha: 0.16)
                      : context.colors.onSurface.withValues(alpha: 0.06),
                ),
                child: Icon(icon, size: 17, color: value ? tone : muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: sheetHeadingStyle(context, size: compact ? 13.5 : 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: sheetBodyStyle(context, size: compact ? 11.5 : 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
