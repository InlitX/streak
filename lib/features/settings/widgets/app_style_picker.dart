import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class AppStylePicker extends StatelessWidget {
  const AppStylePicker({super.key, this.width = 96, this.withDescription = false});

  final double width;
  final bool withDescription;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    void choose(int value) {
      if (settings.appStyle == value) return;
      HapticFeedback.selectionClick();
      settings.setAppStyle(value);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width,
          child: _StyleOption(
            label: context.l10n.style_classic,
            description:
                withDescription ? context.l10n.style_classic_desc : null,
            selected: settings.appStyle == 0,
            preview: const _ClassicSkeleton(),
            onTap: () => choose(0),
          ),
        ),
        SizedBox(width: withDescription ? 18 : 26),
        SizedBox(
          width: width,
          child: _StyleOption(
            label: context.l10n.style_minimal,
            description:
                withDescription ? context.l10n.style_minimal_desc : null,
            selected: settings.appStyle == 1,
            preview: const _MinimalSkeleton(),
            onTap: () => choose(1),
          ),
        ),
      ],
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.label,
    required this.selected,
    required this.preview,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark ? const Color(0xFF2E2E32) : const Color(0xFFDCDCE3);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.62,
            child: AnimatedScale(
              scale: selected ? 1 : 0.94,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141416) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? accent : outline,
                    width: selected ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: selected ? 0.22 : 0),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B1B1F)
                          : const Color(0xFFF3F3F7),
                    ),
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0.72,
                      duration: const Duration(milliseconds: 280),
                      child: preview,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(color: context.tokens.muted, width: 1.2),
                ),
                child: selected
                    ? Icon(LucideIcons.check,
                        size: 9, color: context.colors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : context.tokens.muted,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.tokens.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Skin {
  const _Skin(this.context, this.accent, this.isDark);

  final BuildContext context;
  final Color accent;
  final bool isDark;

  Color get card => isDark ? const Color(0xFF2B2B31) : Colors.white;
  Color get text => context.tokens.muted.withValues(alpha: 0.55);
  Color get faint => context.tokens.muted.withValues(alpha: 0.3);
  Color get tint => accent.withValues(alpha: 0.22);
}

Widget _block(
  double w,
  double h,
  Color color, {
  double radius = 2,
}) =>
    Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

class _ClassicSkeleton extends StatelessWidget {
  const _ClassicSkeleton();

  @override
  Widget build(BuildContext context) {
    final skin = _Skin(
      context,
      context.colors.primary,
      Theme.of(context).brightness == Brightness.dark,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 86;

        Widget habitCard() => Container(
              height: 21 * s,
              padding: EdgeInsets.symmetric(horizontal: 5 * s),
              decoration: BoxDecoration(
                color: skin.card,
                borderRadius: BorderRadius.circular(7 * s),
              ),
              child: Row(
                children: [
                  _block(12 * s, 12 * s, skin.tint, radius: 4 * s),
                  SizedBox(width: 5 * s),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(24 * s, 3.2 * s, skin.text, radius: 2 * s),
                      SizedBox(height: 3 * s),
                      _block(14 * s, 2.4 * s, skin.faint, radius: 2 * s),
                    ],
                  ),
                  const Spacer(),
                  _block(12 * s, 12 * s, skin.tint, radius: 4 * s),
                ],
              ),
            );

        return Padding(
          padding: EdgeInsets.fromLTRB(5 * s, 7 * s, 5 * s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _block(
                    22 * s,
                    6 * s,
                    context.colors.onSurface.withValues(alpha: 0.65),
                    radius: 2 * s,
                  ),
                  const Spacer(),
                  _block(19 * s, 9 * s, skin.accent, radius: 4 * s),
                ],
              ),
              SizedBox(height: 7 * s),
              Container(
                height: 17 * s,
                padding: EdgeInsets.symmetric(horizontal: 5 * s),
                decoration: BoxDecoration(
                  color: skin.card,
                  borderRadius: BorderRadius.circular(7 * s),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(18 * s, 2.8 * s, skin.text, radius: 2 * s),
                    SizedBox(height: 4 * s),
                    Stack(
                      children: [
                        _block(70 * s, 3.4 * s, skin.faint, radius: 2 * s),
                        _block(42 * s, 3.4 * s, skin.accent, radius: 2 * s),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * s),
              habitCard(),
              SizedBox(height: 5 * s),
              habitCard(),
              SizedBox(height: 5 * s),
              habitCard(),
              const Spacer(),
              Container(
                height: 15 * s,
                decoration: BoxDecoration(
                  color: skin.card,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(6 * s),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _block(7 * s, 7 * s, skin.accent, radius: 3.5 * s),
                    _block(7 * s, 7 * s, skin.faint, radius: 3.5 * s),
                    _block(7 * s, 7 * s, skin.faint, radius: 3.5 * s),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MinimalSkeleton extends StatelessWidget {
  const _MinimalSkeleton();

  @override
  Widget build(BuildContext context) {
    final skin = _Skin(
      context,
      context.colors.primary,
      Theme.of(context).brightness == Brightness.dark,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 86;

        Widget wideCard() => Container(
              height: 22 * s,
              padding: EdgeInsets.symmetric(horizontal: 5 * s),
              decoration: BoxDecoration(
                color: skin.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(7 * s),
                border: Border.all(color: skin.faint.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  _block(13 * s, 13 * s, skin.tint, radius: 4.5 * s),
                  SizedBox(width: 5 * s),
                  _block(16 * s, 3.2 * s, skin.text, radius: 2 * s),
                  const Spacer(),
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) SizedBox(width: 2.5 * s),
                    _block(
                      5 * s,
                      9 * s,
                      i == 3 ? skin.accent : skin.tint,
                      radius: 1.8 * s,
                    ),
                  ],
                ],
              ),
            );

        return Padding(
          padding: EdgeInsets.fromLTRB(5 * s, 7 * s, 5 * s, 6 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _block(8 * s, 8 * s, skin.faint, radius: 2.5 * s),
                  const Spacer(),
                  _block(8 * s, 8 * s, skin.faint, radius: 2.5 * s),
                  SizedBox(width: 4 * s),
                  _block(8 * s, 8 * s, skin.text, radius: 4 * s),
                ],
              ),
              SizedBox(height: 8 * s),
              wideCard(),
              SizedBox(height: 5 * s),
              wideCard(),
              SizedBox(height: 5 * s),
              wideCard(),
              const Spacer(),
              Center(
                child: Container(
                  width: 34 * s,
                  height: 11 * s,
                  decoration: BoxDecoration(
                    color: skin.card,
                    borderRadius: BorderRadius.circular(6 * s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _block(5 * s, 5 * s, skin.accent, radius: 2.5 * s),
                      _block(5 * s, 5 * s, skin.faint, radius: 2.5 * s),
                      _block(5 * s, 5 * s, skin.faint, radius: 2.5 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
