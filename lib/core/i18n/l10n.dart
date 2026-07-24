import 'package:flutter/widgets.dart';
import 'package:streak/l10n/app_localizations.dart';

export 'package:streak/l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String categoryLabel(String name) => switch (name) {
        'Health' => l10n.category_health,
        'Fitness' => l10n.category_fitness,
        'Mindfulness' => l10n.category_mindfulness,
        'Productivity' => l10n.category_productivity,
        'Learning' => l10n.category_learning,
        'Finance' => l10n.category_finance,
        _ => name,
      };
}
