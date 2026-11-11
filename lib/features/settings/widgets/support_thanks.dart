import 'package:flutter/material.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/sheet_type.dart';

class SupportThanks extends StatelessWidget {
  const SupportThanks({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ExcludeSemantics(
              child: Image.asset(
                'assets/support-cat.png',
                width: 300,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.support_thanks_title,
            textAlign: TextAlign.center,
            style: sheetTitleStyle(context, size: 22).copyWith(height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.support_thanks_body,
            textAlign: TextAlign.center,
            style: sheetBodyStyle(context, size: 14).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
