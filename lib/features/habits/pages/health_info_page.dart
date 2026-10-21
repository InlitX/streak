import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/services/health_steps.dart';

class HealthInfoPage extends StatelessWidget {
  const HealthInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final points = [
      (LucideIcons.footprints, context.l10n.health_point_read),
      (LucideIcons.smartphone, context.l10n.health_point_local),
      (LucideIcons.toggleLeft, context.l10n.health_point_off),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => AppNavigator.pop(),
        ),
        title: const Text('Health Connect'),
      ),
      body: ListView(
        padding: context.pagePadding(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.footprints, size: 32, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.health_intro,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          for (final (icon, text) in points)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: context.tokens.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: HealthSteps.openSettings,
            icon: const Icon(LucideIcons.shieldCheck, size: 18),
            label: Text(context.l10n.health_manage),
          ),
        ],
      ),
    );
  }
}
