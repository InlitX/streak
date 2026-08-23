import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/express/express_type.dart';
import 'package:streak/core/minimal/minimal_type.dart';
import 'package:streak/features/settings/state/settings_controller.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = context.watch<SettingsController>();
    final express = style.isExpressStyle;
    final minimal = style.isMinimalStyle;
    return Padding(
      padding: EdgeInsets.only(left: express ? 6 : 4, bottom: minimal ? 12 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              express || minimal ? text : text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: minimal
                  ? MinimalType.title(
                      16,
                      weight: 700,
                      color: context.colors.onSurface,
                    )
                  : express
                  ? ExpressType.headline.at(
                      15,
                      weight: 800,
                      color: context.colors.primary,
                    )
                  : TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: context.tokens.muted,
                    ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
