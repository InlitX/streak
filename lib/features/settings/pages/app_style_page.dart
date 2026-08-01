import 'package:flutter/material.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/settings/widgets/app_style_picker.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';

class AppStylePage extends StatelessWidget {
  const AppStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 52),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                ((constraints.maxWidth - 44 - 18) / 2).clamp(110.0, 160.0);
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              children: [
                MinimalTitle(
                  title: context.l10n.app_style,
                  subtitle: context.l10n.app_style_sub,
                ),
                AppStylePicker(width: width, withDescription: true),
              ],
            );
          },
        ),
      ),
    );
  }
}
