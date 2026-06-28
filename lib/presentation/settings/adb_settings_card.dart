import 'package:flutter/material.dart';

import '../../app/localization/l10n_extension.dart';
import '../dashboard/automation_controller.dart';

/// Card for low-frequency ADB path and connection settings.
class ADBSettingsCard extends StatelessWidget {
  /// Creates an ADB settings card.
  const ADBSettingsCard({required this.controller});

  /// Controller that owns ADB operations.
  final AutomationController controller;

  @override
  Widget build(BuildContext context) {
    final adbManager = controller.adbManager;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.l10n.adbSettings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(context.l10n.adbPath(adbManager.adbPath ?? context.l10n.notDiscovered)),
            Text(context.l10n.adbVersion(adbManager.adbVersion ?? context.l10n.unknown)),
            Text(context.l10n.connectionStatus(adbManager.connectionStatus)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _showADBPathDialog(context),
                  icon: const Icon(Icons.folder_open),
                  label: Text(context.l10n.browse),
                ),
                OutlinedButton.icon(
                  onPressed: controller.testADBConnection,
                  icon: const Icon(Icons.cable),
                  label: Text(context.l10n.testConnection),
                ),
                OutlinedButton.icon(
                  onPressed: controller.rescanADB,
                  icon: const Icon(Icons.search),
                  label: Text(context.l10n.rescan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showADBPathDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.adbManager.adbPath ?? '');
    final path = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n.adbPathTitle),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.adbExePath,
            hintText: r'C:\LDPlayer\LDPlayer9\adb.exe',
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: Text(context.l10n.save)),
        ],
      ),
    );
    textController.dispose();
    if (path != null && path.trim().isNotEmpty) {
      await controller.setADBPath(path);
    }
  }
}

