import 'package:flutter/material.dart';
import 'package:streak/app/theme/app_tokens.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final muted = context.tokens.muted;
    final haloSize = compact ? 72.0 : 108.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(

          horizontal: compact ? 8 : 40,
          vertical: compact ? 28 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: haloSize,
              height: haloSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.16),
                    scheme.primary.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: compact ? 32 : 46,
                color: scheme.primary,
              ),
            ),
            SizedBox(height: compact ? 18 : 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: scheme.onSurface,
                height: 1.25,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: compact ? 13.5 : 14.5,
                  height: 1.55,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? 22 : 30),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
