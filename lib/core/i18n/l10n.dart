import 'package:flutter/widgets.dart';
import 'package:streak/l10n/app_localizations.dart';

export 'package:streak/l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
