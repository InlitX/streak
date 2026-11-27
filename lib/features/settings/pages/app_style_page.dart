import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/express/express_page.dart';
import 'package:streak/core/extensions/inset_extensions.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/features/settings/state/settings_controller.dart';
import 'package:streak/features/settings/widgets/app_style_picker.dart';
import 'package:streak/features/settings/widgets/minimal_settings_widgets.dart';

class AppStylePage extends StatelessWidget {
  const AppStylePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<SettingsController>().isExpressStyle) {
      return ExpressScaffold(
        title: context.l10n.app_style,
        subtitle: context.l10n.app_style_sub,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => AppStylePicker(
              width: ((constraints.maxWidth - 32) / 3).clamp(80.0, 150.0),
            ),
          ),
          const SizedBox(height: 28),
          const AppStyleLegend(),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(toolbarHeight: 52),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              ((constraints.maxWidth - 44 - 32) / 3).clamp(80.0, 150.0);
          return ListView(
            padding: context.pagePadding(22, 0, 22, 40),
            children: [
              MinimalTitle(
                title: context.l10n.app_style,
                subtitle: context.l10n.app_style_sub,
              ),
              AppStylePicker(width: width),
              const SizedBox(height: 32),
              const AppStyleLegend(),
            ],
          );
        },
      ),
    );
  }
}
