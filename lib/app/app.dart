import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../presentation/dashboard/dashboard_page.dart';
import 'localization/language_manager.dart';
import 'theme.dart';

/// Root widget for the Game Helper application.
class GameHelperApp extends StatefulWidget {
  /// Creates the root Game Helper application widget.
  const GameHelperApp({super.key, this.languageManager});

  /// Manages the current application locale.
  final LanguageManager? languageManager;

  @override
  State<GameHelperApp> createState() => _GameHelperAppState();
}

class _GameHelperAppState extends State<GameHelperApp> {
  late final LanguageManager _languageManager;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _languageManager = widget.languageManager ?? LanguageManager();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await _languageManager.loadPreference();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _languageManager,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: GameHelperTheme.dark(),
        locale: _languageManager.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DashboardPage(languageManager: _languageManager),
      ),
    );
  }
}
