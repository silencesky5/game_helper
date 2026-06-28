import 'package:flutter/material.dart';

import '../../app/localization/l10n_extension.dart';
import '../../app/localization/language_manager.dart';
import '../dashboard/automation_controller.dart';
import 'adb_settings_card.dart';

/// Low-frequency application settings page separated from the runtime dashboard.
class SettingsPage extends StatefulWidget {
  /// Creates the settings page.
  const SettingsPage({super.key, this.controller, this.languageManager});

  /// Optional controller shared with the dashboard for ADB operations.
  final AutomationController? controller;

  /// Optional language manager for runtime language changes.
  final LanguageManager? languageManager;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AutomationController _controller;
  late final LanguageManager _languageManager;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AutomationController();
    _languageManager = widget.languageManager ?? LanguageManager();
    if (widget.languageManager == null) {
      _languageManager.loadPreference();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('General', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.l10n.language, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _languageManager,
                    builder: (BuildContext context, _) => DropdownButton<AppLanguage>(
                      value: _languageManager.currentLanguage,
                      onChanged: (AppLanguage? language) {
                        if (language != null) _languageManager.changeLanguage(language);
                      },
                      items: const <DropdownMenuItem<AppLanguage>>[
                        DropdownMenuItem<AppLanguage>(value: AppLanguage.zhTw, child: Text('繁體中文')),
                        DropdownMenuItem<AppLanguage>(value: AppLanguage.en, child: Text('English')),
                        DropdownMenuItem<AppLanguage>(value: AppLanguage.ja, child: Text('日本語')),
                        DropdownMenuItem<AppLanguage>(value: AppLanguage.ko, child: Text('한국어')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(leading: Icon(Icons.dark_mode), title: Text('Theme'), subtitle: Text('Dark theme')),
                  const ListTile(leading: Icon(Icons.extension), title: Text('Plugin'), subtitle: Text('Plugin defaults and marketplace settings')),
                  const ListTile(leading: Icon(Icons.system_update), title: Text('Update'), subtitle: Text('Update checks coming soon')),
                  const ListTile(leading: Icon(Icons.info_outline), title: Text('About'), subtitle: Text('Game Helper Desktop Console')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ADBSettingsCard(controller: _controller),
        ],
      ),
    );
  }
}
