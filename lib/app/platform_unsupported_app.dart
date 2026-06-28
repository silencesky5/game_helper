import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'localization/l10n_extension.dart';
import 'theme.dart';

/// Minimal non-Windows shell used to prevent the automation dashboard from
/// running inside Android emulators.
class PlatformUnsupportedApp extends StatelessWidget {
  /// Creates a platform warning application shell.
  const PlatformUnsupportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).desktopRequiredTitle,
      theme: GameHelperTheme.dark(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.desktopRequiredMessage,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
