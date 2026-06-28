import 'package:flutter/widgets.dart';
import 'package:game_helper/l10n/app_localizations.dart';

/// Convenient access to generated localizations from widget build contexts.
extension AppLocalizationsX on BuildContext {
  /// Localized strings for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
