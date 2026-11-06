import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_surface.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/minimal/minimal_kit.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

const importApps = [
  'Loop',
  'HabitKit',
  'Habitica',
  'HabitBull',
  'Habitify',
  'Habit Builder',
  'CSV',
];

class ImportAppsCard extends StatelessWidget {
  const ImportAppsCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final body = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: const _CardBody(),
      ),
    );
    if (settings.isExpressStyle) {
      return ExpressCard(padding: EdgeInsets.zero, clip: true, child: body);
    }
    if (settings.isMinimalStyle) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: MinimalCard(padding: EdgeInsets.zero, child: body),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Marquee(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.import_from_app,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.import_card_body,
                        style: text.bodySmall?.copyWith(
                          color: context.tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ink.withValues(alpha: 0.07),
                  ),
                  child: Icon(LucideIcons.arrowRight, size: 17, color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Marquee extends StatefulWidget {
  const _Marquee();

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  static const _tile = 108.0;
  static const _gap = 10.0;
  static const _height = 44.0;
  static const _period = (_tile + _gap) * 7;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = context.colors.onSurface;
    final label = Theme.of(context).textTheme.labelLarge;
    final strip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var round = 0; round < 4; round++)
          for (final name in importApps)
            Padding(
              padding: const EdgeInsets.only(right: _gap),
              child: Container(
                width: _tile,
                height: _height,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: label?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: _height,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: AnimatedBuilder(
                animation: _ctrl,
                child: RepaintBoundary(child: strip),
                builder: (context, child) => Transform.translate(
                  offset: Offset(-_ctrl.value * _period, 0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
