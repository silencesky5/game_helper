import 'package:flutter/material.dart';

import '../../domain/automation/automation_action.dart';
import '../../domain/automation/automation_config.dart';
import '../../domain/automation/automation_session.dart';
import '../../domain/automation/automation_state.dart';
import '../../domain/screenshot/device_screenshot.dart';
import '../../infrastructure/adb/adb_manager.dart';
import '../../app/localization/l10n_extension.dart';
import '../../app/localization/language_manager.dart';
import 'automation_controller.dart';
import 'dashboard_strings.dart';
import '../plugins/plugins_page.dart';
import '../settings/settings_page.dart';
import 'widgets/start_button.dart';

/// Dashboard entry point for the desktop automation console.
class DashboardPage extends StatefulWidget {
  /// Creates the dashboard page.
  const DashboardPage({super.key, this.controller, this.languageManager});

  /// Controller used to start automation.
  final AutomationController? controller;

  /// Manages runtime locale changes from the Settings page.
  final LanguageManager? languageManager;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AutomationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AutomationController();
    _controller.addListener(_onControllerChanged);
    _controller.initializeDesktopConsole();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AutomationSession> sessions = _controller.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.desktopConsoleTitle),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_controller.running ? context.l10n.runningPipeline : context.l10n.ready)),
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (int index) => _openNavigationDestination(context, index),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text(context.l10n.dashboard)),
              NavigationRailDestination(icon: Icon(Icons.extension), label: Text(context.l10n.plugins)),
              const NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text(DashboardStrings.statistics)),
              const NavigationRailDestination(icon: Icon(Icons.article), label: Text(DashboardStrings.logs)),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text(context.l10n.settings)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(DashboardStrings.platformTitle, style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      Text(context.l10n.deviceSessions),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AdbStatusPanel(controller: _controller),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 3,
                    child: sessions.isEmpty
                        ? _EmptyDeviceState(detecting: _controller.detecting)
                        : ListView.separated(
                            itemCount: sessions.length,
                            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
                            itemBuilder: (BuildContext context, int index) => _DeviceCard(session: sessions[index], controller: _controller),
                          ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _LogPanel(logs: _controller.logs),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _openNavigationDestination(BuildContext context, int index) {
    if (index == 1) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PluginsPage()));
    } else if (index == 4) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettingsPage(controller: _controller, languageManager: widget.languageManager)));
    }
  }
}

class _AdbStatusPanel extends StatelessWidget {
  const _AdbStatusPanel({required this.controller});

  final AutomationController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.adbManager.validationSnapshot;
    final DateTime? lastValidation = snapshot.lastValidation;
    final String? message = snapshot.message;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(DashboardStrings.adbStatus, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 12),
                      _StatusBadge(label: DashboardStrings.adbStatusLabel(snapshot.status), color: _adbColor(snapshot.status)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: DashboardStrings.version, value: snapshot.version ?? context.l10n.unknown),
                  _InfoRow(label: DashboardStrings.connectedDevices, value: snapshot.connectedDevices.toString()),
                  _InfoRow(label: DashboardStrings.executablePath, value: snapshot.path ?? context.l10n.notDiscovered),
                  _InfoRow(
                    label: DashboardStrings.lastScan,
                    value: lastValidation == null ? context.l10n.never : lastValidation.toLocal().toString().split('.').first,
                  ),
                  if (message != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(DashboardStrings.adbMessage(message), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              direction: Axis.vertical,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: controller.detecting ? null : controller.initializeDesktopConsole,
                  icon: const Icon(Icons.refresh),
                  label: Text(controller.detecting ? context.l10n.detecting : DashboardStrings.rescanAdb),
                ),
                StartButton(onPressed: controller.running || controller.sessions.isEmpty ? null : controller.start),
                OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.stop), label: const Text(DashboardStrings.stopAll)),
                OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.restart_alt), label: const Text(DashboardStrings.restartAll)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _adbColor(AdbRuntimeStatus status) => switch (status) {
        AdbRuntimeStatus.connected => Colors.green,
        AdbRuntimeStatus.available => Colors.blue,
        AdbRuntimeStatus.noDevice => Colors.amber,
        AdbRuntimeStatus.invalid => Colors.deepOrange,
        AdbRuntimeStatus.notFound => Colors.red,
      };
}

class _EmptyDeviceState extends StatelessWidget {
  const _EmptyDeviceState({required this.detecting});

  final bool detecting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.desktop_windows, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            detecting ? context.l10n.detectingDevicesMessage : context.l10n.noAdbDevicesDetected,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.startLdPlayerHint),
        ],
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.runtimeLogs, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: logs.isEmpty
                ? Text(context.l10n.waitingForEvents)
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (BuildContext context, int index) => Text(
                      logs[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.session, required this.controller});

  final AutomationSession session;
  final AutomationController controller;

  @override
  Widget build(BuildContext context) {
    final DeviceScreenshot? screenshot = controller.screenshotRepository.latest(session.device.id);
    final String pluginName = session.plugin?.displayName ?? '未指定';
    final String pluginVersion = session.plugin?.version ?? DashboardStrings.na;
    final String characterLevel = session.character.level == null ? '' : ' / ${session.character.level}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EmulatorSessionHeader(
              session: session,
              gameName: pluginName,
              pluginVersion: pluginVersion,
              characterLabel: '${session.character.displayName}$characterLevel',
              onRename: () => _showRenameDialog(context),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: session.plugin?.id ?? 'unassigned',
              decoration: const InputDecoration(labelText: '遊戲', isDense: true),
              items: controller.availablePlugins.map((plugin) => DropdownMenuItem<String>(value: plugin.id, child: Text(plugin.displayName))).toList(growable: false),
              onChanged: (String? pluginId) {
                if (pluginId != null) controller.assignPlugin(session, pluginId);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _AutomationStatusBadge(state: session.state),
                _StatusBadge(label: session.device.isOnline ? DashboardStrings.adbConnected : DashboardStrings.adbStatusLabel(AdbRuntimeStatus.noDevice), color: session.device.isOnline ? RuntimeStateColors.running : RuntimeStateColors.error),
                _StatusBadge(label: screenshot == null ? DashboardStrings.screenshotMissing : DashboardStrings.screenshotReady, color: screenshot == null ? RuntimeStateColors.error : RuntimeStateColors.running),
              ],
            ),
            const SizedBox(height: 12),
            _ResponsiveCardRow(
              children: <Widget>[
                _RuntimeMonitor(session: session),
                _AutomationProgress(session: session, actions: controller.automationActionsFor(session)),
                _ScreenshotSection(screenshot: screenshot, onRefresh: () => controller.captureScreenshot(session)),
              ],
            ),
            const SizedBox(height: 12),
            _ResponsiveCardRow(
              children: <Widget>[
                _RuntimeErrorPanel(session: session),
                _RuntimeTimeline(events: controller.recentEventsFor(session.device.id)),
              ],
            ),
            const SizedBox(height: 12),
            _AutomationDebugPanel(session: session, controller: controller),
            const SizedBox(height: 12),
            const _ReservedRuntimeSections(),
            const SizedBox(height: 12),
            _ActionGroups(
              session: session,
              controller: controller,
              onPluginSettings: () => _showPluginSettings(context),
              onAutomationLogic: () => _showAutomationLogicDialog(context),
              onDeviceInfo: () => _showDeviceInfoDialog(context, screenshot),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final textController = TextEditingController(text: session.device.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(DashboardStrings.deviceName),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: DashboardStrings.deviceNameHint),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: Text(context.l10n.save)),
        ],
      ),
    );
    textController.dispose();
    if (name != null) controller.renameSessionDevice(session, name);
  }


  Future<void> _showAutomationLogicDialog(BuildContext context) async {
    final actions = controller.automationActionsFor(session);
    AutomationConfig draft = session.automationConfig ?? AutomationConfig.defaultsFor(session.device.id, actions);
    final AutomationConfig? saved = await showDialog<AutomationConfig>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final Map<String, List<AutomationActionDefinition>> byCategory = <String, List<AutomationActionDefinition>>{};
          for (final AutomationActionDefinition action in actions) {
            byCategory.putIfAbsent(action.category, () => <AutomationActionDefinition>[]).add(action);
          }
          return AlertDialog(
            title: Text('${session.plugin?.displayName ?? '未指定'}\n${DashboardStrings.taskLogic}'),
            content: SizedBox(
              width: 420,
              child: actions.isEmpty
                  ? const Text(DashboardStrings.noAutomationActions)
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final entry in byCategory.entries) ...<Widget>[
                            Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                            const Divider(),
                            for (final action in entry.value)
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(action.displayName),
                                subtitle: action.description.isEmpty ? null : Text(action.description),
                                value: draft.isEnabled(action.id),
                                onChanged: (bool? value) => setDialogState(() => draft = draft.toggle(action.id, value ?? false)),
                              ),
                            const SizedBox(height: 8),
                          ],
                          Text(DashboardStrings.priority, style: Theme.of(context).textTheme.titleMedium),
                          const Divider(),
                          for (final actionId in draft.priorityOrder)
                            if (actions.any((AutomationActionDefinition action) => action.id == actionId))
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(radius: 12, child: Text('${draft.priorityOrder.indexOf(actionId) + 1}')),
                                title: Text(actions.firstWhere((AutomationActionDefinition action) => action.id == actionId).displayName),
                                trailing: Wrap(
                                  children: <Widget>[
                                    IconButton(
                                      tooltip: DashboardStrings.moveUp,
                                      onPressed: draft.priorityOrder.indexOf(actionId) == 0
                                          ? null
                                          : () => setDialogState(() => draft = draft.reorder(actionId, draft.priorityOrder.indexOf(actionId) - 1)),
                                      icon: const Icon(Icons.arrow_upward),
                                    ),
                                    IconButton(
                                      tooltip: DashboardStrings.moveDown,
                                      onPressed: draft.priorityOrder.indexOf(actionId) == draft.priorityOrder.length - 1
                                          ? null
                                          : () => setDialogState(() => draft = draft.reorder(actionId, draft.priorityOrder.indexOf(actionId) + 1)),
                                      icon: const Icon(Icons.arrow_downward),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => setDialogState(() => draft = draft.setAll(actions, true)), child: const Text(DashboardStrings.selectAll)),
              TextButton(onPressed: () => setDialogState(() => draft = draft.setAll(actions, false)), child: const Text(DashboardStrings.clearAll)),
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.l10n.cancel)),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(draft), child: Text(context.l10n.save)),
            ],
          );
        },
      ),
    );
    if (saved != null) await controller.saveAutomationConfig(session, saved);
  }

  Future<void> _showPluginSettings(BuildContext context) async {
    final plugin = session.plugin;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(DashboardStrings.settingsWithIcon),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${DashboardStrings.internalName}  ${plugin?.name ?? DashboardStrings.na}'),
            Text('${DashboardStrings.pluginVersion}  ${plugin?.version ?? DashboardStrings.na}'),
            Text('${DashboardStrings.author}  ${plugin?.author ?? DashboardStrings.na}'),
            Text('${DashboardStrings.pluginLog}  ${DashboardStrings.seeRuntimeLogs}'),
            Text('${DashboardStrings.debug}  ${DashboardStrings.enabledFromDashboard}'),
            Text('${DashboardStrings.reloadPlugin}  ${DashboardStrings.comingSoon}'),
            Text('${DashboardStrings.ocrTest}  ${DashboardStrings.comingSoon}'),
            Text('${DashboardStrings.imageTest}  ${DashboardStrings.comingSoon}'),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text(DashboardStrings.close)),
        ],
      ),
    );
  }

  Future<void> _showDeviceInfoDialog(BuildContext context, DeviceScreenshot? screenshot) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text(DashboardStrings.deviceInfo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InfoRow(label: DashboardStrings.androidVersion, value: session.device.androidVersion),
              _InfoRow(label: DashboardStrings.resolution, value: session.device.resolution),
              _InfoRow(label: DashboardStrings.brand, value: session.device.manufacturer),
              _InfoRow(label: DashboardStrings.model, value: session.device.model),
              _InfoRow(label: DashboardStrings.serial, value: session.device.id),
              _InfoRow(label: DashboardStrings.adbStatus, value: session.device.isOnline ? '🟢 ${DashboardStrings.adbConnected}' : '🔴 ${session.device.status.name}'),
              _InfoRow(label: DashboardStrings.screenshot, value: screenshot == null ? '🔴 ${DashboardStrings.captureFailed}' : '🟢 ${DashboardStrings.ready}'),
              const _InfoRow(label: DashboardStrings.cpu, value: DashboardStrings.na),
              const _InfoRow(label: DashboardStrings.memory, value: DashboardStrings.na),
              _InfoRow(label: DashboardStrings.pluginVersion, value: session.plugin?.version ?? DashboardStrings.na),
              _InfoRow(label: DashboardStrings.lastCapture, value: screenshot?.updatedAt.toLocal().toString().split('.').first ?? context.l10n.never),
              _InfoRow(label: DashboardStrings.imageSize, value: screenshot?.sizeLabel ?? DashboardStrings.unknown),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text(DashboardStrings.close)),
        ],
      ),
    );
  }
}


class RuntimeStateColors {
  static const Color idle = Colors.grey;
  static const Color running = Colors.green;
  static const Color waiting = Colors.blue;
  static const Color paused = Colors.orange;
  static const Color completed = Colors.cyan;
  static const Color error = Colors.red;
}

class _EmulatorSessionHeader extends StatelessWidget {
  const _EmulatorSessionHeader({required this.session, required this.gameName, required this.pluginVersion, required this.characterLabel, required this.onRename});

  final AutomationSession session;
  final String gameName;
  final String pluginVersion;
  final String characterLabel;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(session.device.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('$gameName  v$pluginVersion', style: Theme.of(context).textTheme.titleMedium),
                Text('角色：$characterLabel'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: <Widget>[
                    Text('${DashboardStrings.deviceId}: ${session.device.id}', style: Theme.of(context).textTheme.bodySmall),
                    Text('${DashboardStrings.resolution}: ${session.device.resolution}', style: Theme.of(context).textTheme.bodySmall),
                    Text('${DashboardStrings.androidVersion}: ${session.device.androidVersion}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          IconButton(tooltip: DashboardStrings.renameDevice, onPressed: onRename, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
    );
  }
}

class _RuntimeMonitor extends StatelessWidget {
  const _RuntimeMonitor({required this.session});

  final AutomationSession session;

  @override
  Widget build(BuildContext context) {
    if (session.startedAt == null && session.state == AutomationState.idle) {
      return const _SectionCard(title: DashboardStrings.runtime, child: Text(DashboardStrings.automationNotStarted));
    }
    final DateTime? startedAt = session.startedAt;
    final runtime = startedAt == null ? '--' : DateTime.now().difference(startedAt).toString().split('.').first;
    return _SectionCard(
      title: DashboardStrings.runtime,
      trailing: _AutomationStatusBadge(state: session.state),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          _RuntimeInfoBlock(label: DashboardStrings.currentTask, value: _localizedRuntimeValue(_fallbackText(session.currentStep, DashboardStrings.noActiveTask))),
          _RuntimeInfoBlock(label: DashboardStrings.nextTask, value: _localizedRuntimeValue(_fallbackText(session.nextStep, DashboardStrings.noActiveTask))),
          _RuntimeInfoBlock(label: DashboardStrings.currentScene, value: _localizedRuntimeValue(_fallbackText(session.currentScene, DashboardStrings.unknown))),
          _RuntimeInfoBlock(label: DashboardStrings.elapsedTime, value: runtime),
        ],
      ),
    );
  }
}

class _RuntimeInfoBlock extends StatelessWidget {
  const _RuntimeInfoBlock({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ]),
      );
}

class _RuntimeErrorPanel extends StatelessWidget {
  const _RuntimeErrorPanel({required this.session});
  final AutomationSession session;
  @override
  Widget build(BuildContext context) {
    if (session.state != AutomationState.failed) {
      return const _SectionCard(title: DashboardStrings.automationError, child: Text(DashboardStrings.noRuntimeErrors));
    }
    final timestamp = DateTime.now().toLocal().toString().split(' ').last.split('.').first;
    return _SectionCard(
      title: DashboardStrings.automationError,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(session.currentStep, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: RuntimeStateColors.error)),
        const SizedBox(height: 8),
        const _InfoRow(label: DashboardStrings.reason, value: DashboardStrings.runtimeReportedFailure),
        const _InfoRow(label: DashboardStrings.retryCount, value: DashboardStrings.na),
        _InfoRow(label: DashboardStrings.lastAction, value: session.currentStep),
        _InfoRow(label: DashboardStrings.timestamp, value: timestamp),
      ]),
    );
  }
}

class _AutomationProgress extends StatelessWidget {
  const _AutomationProgress({required this.session, required this.actions});
  final AutomationSession session;
  final List<AutomationActionDefinition> actions;
  @override
  Widget build(BuildContext context) {
    final total = actions.isEmpty ? 10 : actions.length;
    final completed = session.state == AutomationState.completed ? total : 0;
    final value = total == 0 ? 0.0 : completed / total;
    return _SectionCard(
      title: DashboardStrings.todaysProgress,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        LinearProgressIndicator(value: value, minHeight: 10),
        const SizedBox(height: 8),
        Text('${DashboardStrings.completed} $completed / $total'),
        Text('${(value * 100).round()}%'),
      ]),
    );
  }
}

String _fallbackText(String value, String fallback) => value.trim().isEmpty ? fallback : value;

String _localizedRuntimeValue(String value) => switch (value) {
      'Waiting' => DashboardStrings.automationState(AutomationState.stopped),
      'Unknown' => DashboardStrings.unknown,
      'Completed' => DashboardStrings.completed,
      'Error' => DashboardStrings.automationState(AutomationState.failed),
      _ => value,
    };

class _ScreenshotSection extends StatelessWidget {
  const _ScreenshotSection({required this.screenshot, required this.onRefresh});
  final DeviceScreenshot? screenshot;
  final VoidCallback onRefresh;
  void _openViewer(BuildContext context) {
    final DeviceScreenshot? validScreenshot = _validScreenshotOrNull(screenshot);
    if (validScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(DashboardStrings.unableToLoadScreenshot)));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        child: SizedBox(
          width: 720,
          height: 640,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Text(DashboardStrings.screenshotViewer, style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Expanded(child: InteractiveViewer(minScale: 0.25, maxScale: 6, child: Center(child: Image.memory(validScreenshot.pngBytes, fit: BoxFit.contain, errorBuilder: _imageErrorBuilder)))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DeviceScreenshot? validScreenshot = _validScreenshotOrNull(screenshot);
    final time = validScreenshot == null ? context.l10n.never : validScreenshot.updatedAt.toLocal().toString().split(' ').last.split('.').first;
    return _SectionCard(
      title: DashboardStrings.screenshot,
      trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
      child: Column(children: <Widget>[
        _ScreenshotPreview(screenshot: screenshot),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          OutlinedButton(onPressed: onRefresh, child: const Text(DashboardStrings.refreshScreenshot)),
          OutlinedButton(onPressed: validScreenshot == null ? null : () => _openViewer(context), child: const Text(DashboardStrings.viewOriginal)),
          const OutlinedButton(onPressed: null, child: Text(DashboardStrings.saveImage)),
        ]),
      ]),
    );
  }
}


class _ResponsiveCardRow extends StatelessWidget {
  const _ResponsiveCardRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked = constraints.maxWidth < 900;
        final double spacing = 16;
        final double itemWidth = stacked ? constraints.maxWidth : (constraints.maxWidth - spacing * (children.length - 1)) / children.length;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((Widget child) => SizedBox(width: itemWidth.clamp(260.0, constraints.maxWidth).toDouble(), child: child)).toList(growable: false),
        );
      },
    );
  }
}

DeviceScreenshot? _validScreenshotOrNull(DeviceScreenshot? screenshot) {
  if (screenshot == null) return null;
  final bytes = screenshot.pngBytes;
  if (bytes.length < 8) return null;
  const List<int> pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < pngSignature.length; i += 1) {
    if (bytes[i] != pngSignature[i]) return null;
  }
  return screenshot;
}

Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) => const _ScreenshotPlaceholder(label: DashboardStrings.screenshotFailed);

class _ScreenshotPlaceholder extends StatelessWidget {
  const _ScreenshotPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.image_not_supported_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RuntimeTimeline extends StatelessWidget {
  const _RuntimeTimeline({required this.events});
  final List<String> events;
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: DashboardStrings.recentEvents,
        child: events.isEmpty
            ? const Text(DashboardStrings.noRecentEvents)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events.take(20).map((String event) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(event, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    )).toList(growable: false),
              ),
      );
}

class _ReservedRuntimeSections extends StatelessWidget {
  const _ReservedRuntimeSections();
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const <Widget>[
          _PlaceholderExpansion(title: DashboardStrings.performance),
          _PlaceholderExpansion(title: DashboardStrings.ocr),
          _PlaceholderExpansion(title: DashboardStrings.memory),
          _PlaceholderExpansion(title: DashboardStrings.pluginStatus),
          _PlaceholderExpansion(title: DashboardStrings.statistics),
        ],
      );
}

class _PlaceholderExpansion extends StatelessWidget {
  const _PlaceholderExpansion({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: ExpansionTile(title: Text(title), initiallyExpanded: false, children: const <Widget>[Padding(padding: EdgeInsets.all(8), child: Text(DashboardStrings.reservedDiagnostics))]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final Widget? trailingWidget = trailing;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[Text(title, style: Theme.of(context).textTheme.titleMedium), const Spacer(), if (trailingWidget != null) trailingWidget]),
          const SizedBox(height: 10),
          child,
        ]),
      );
  }
}

class _AutomationDebugPanel extends StatefulWidget {
  const _AutomationDebugPanel({required this.session, required this.controller});

  final AutomationSession session;
  final AutomationController controller;

  @override
  State<_AutomationDebugPanel> createState() => _AutomationDebugPanelState();
}

class _AutomationDebugPanelState extends State<_AutomationDebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final controller = widget.controller;
    final GrowStoneDebugResult? growStone = controller.growStoneDebugFor(session.device.id);
    final String scene = controller.debugSceneFor(session.device.id)?.name ?? session.currentScene;
    final rect = growStone?.rect;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: <Widget>[
                Icon(_expanded ? Icons.expand_more : Icons.chevron_right),
                Text(DashboardStrings.automationDebug, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                const Text(DashboardStrings.debugMode),
                Switch(
                  value: controller.debugModeFor(session.device.id),
                  onChanged: (bool value) => controller.toggleDebugMode(session, value),
                ),
              ],
            ),
          ),
          if (_expanded) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(onPressed: () => controller.detectScene(session), child: const Text(DashboardStrings.detectScene)),
              OutlinedButton(onPressed: () => controller.detectGrowStone(session), child: const Text(DashboardStrings.detectGrowStone)),
              OutlinedButton(onPressed: () => controller.testGrowStoneTap(session), child: const Text(DashboardStrings.testTap)),
              OutlinedButton(onPressed: () => controller.captureScreenshot(session), child: const Text(DashboardStrings.screenshot)),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(label: DashboardStrings.currentScene, value: _formatScene(scene)),
          _InfoRow(label: DashboardStrings.found, value: growStone == null ? DashboardStrings.na : (growStone.found ? DashboardStrings.yes : DashboardStrings.no)),
          _InfoRow(label: DashboardStrings.confidence, value: growStone?.confidence?.toStringAsFixed(2) ?? DashboardStrings.na),
          _InfoRow(label: DashboardStrings.left, value: rect?.left.toStringAsFixed(0) ?? DashboardStrings.na),
          _InfoRow(label: DashboardStrings.top, value: rect?.top.toStringAsFixed(0) ?? DashboardStrings.na),
          _InfoRow(label: DashboardStrings.right, value: rect?.right.toStringAsFixed(0) ?? DashboardStrings.na),
            _InfoRow(label: DashboardStrings.bottom, value: rect?.bottom.toStringAsFixed(0) ?? DashboardStrings.na),
          ],
        ],
      ),
    );
  }

  String _formatScene(String scene) {
    if (scene.isEmpty) return DashboardStrings.unknown;
    return _localizedRuntimeValue(scene);
  }
}


class _ActionGroups extends StatelessWidget {
  const _ActionGroups({required this.session, required this.controller, required this.onPluginSettings, required this.onAutomationLogic, required this.onDeviceInfo});

  final AutomationSession session;
  final AutomationController controller;
  final VoidCallback onPluginSettings;
  final VoidCallback onAutomationLogic;
  final VoidCallback onDeviceInfo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _ButtonCluster(children: <Widget>[
          OutlinedButton(onPressed: () => controller.captureScreenshot(session), child: const Text(DashboardStrings.adbScreenshot)),
          OutlinedButton(onPressed: controller.running ? null : controller.start, child: const Text(DashboardStrings.startAutomation)),
          OutlinedButton(onPressed: () => controller.detectCharacter(session), child: const Text(DashboardStrings.detectCharacter)),
          OutlinedButton(onPressed: onPluginSettings, child: const Text(DashboardStrings.settingsWithIcon)),
          OutlinedButton(onPressed: onAutomationLogic, child: const Text(DashboardStrings.taskLogic)),
        ]),
        _ButtonCluster(children: <Widget>[
          OutlinedButton(onPressed: () => controller.restartSession(session), child: Text(context.l10n.restartSession)),
          OutlinedButton(onPressed: onDeviceInfo, child: const Text(DashboardStrings.deviceInfo)),
        ]),
      ],
    );
  }
}

class _ButtonCluster extends StatelessWidget {
  const _ButtonCluster({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.state});

  final AutomationState state;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      AutomationState.running => (DashboardStrings.automationState(AutomationState.running), RuntimeStateColors.running),
      AutomationState.paused => (DashboardStrings.automationState(AutomationState.paused), RuntimeStateColors.paused),
      AutomationState.completed => (DashboardStrings.automationState(AutomationState.completed), RuntimeStateColors.completed),
      AutomationState.failed => (DashboardStrings.automationState(AutomationState.failed), RuntimeStateColors.error),
      AutomationState.stopped => (DashboardStrings.automationState(AutomationState.stopped), RuntimeStateColors.waiting),
      AutomationState.idle => (DashboardStrings.automationState(AutomationState.idle), RuntimeStateColors.idle),
    };
    return _InfoRow(label: DashboardStrings.currentStatus, value: label, valueColor: color);
  }
}

class _AutomationStatusBadge extends StatelessWidget {
  const _AutomationStatusBadge({required this.state});

  final AutomationState state;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      AutomationState.failed => (DashboardStrings.automationError, RuntimeStateColors.error),
      AutomationState.paused => (DashboardStrings.automationBadge(AutomationState.paused), RuntimeStateColors.paused),
      AutomationState.running => (DashboardStrings.automationBadge(AutomationState.running), RuntimeStateColors.running),
      AutomationState.stopped => (DashboardStrings.automationBadge(AutomationState.stopped), RuntimeStateColors.waiting),
      AutomationState.completed => (DashboardStrings.automationBadge(AutomationState.completed), RuntimeStateColors.completed),
      AutomationState.idle => (DashboardStrings.automationBadge(AutomationState.idle), RuntimeStateColors.idle),
    };
    return _StatusBadge(label: label, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: valueColor == null ? null : TextStyle(color: valueColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}



class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({required this.screenshot});

  final DeviceScreenshot? screenshot;

  @override
  Widget build(BuildContext context) {
    final DeviceScreenshot? validScreenshot = _validScreenshotOrNull(screenshot);
    return Container(
      width: 100,
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: validScreenshot == null
          ? const _ScreenshotPlaceholder(label: DashboardStrings.noScreenshotAvailable)
          : InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext dialogContext) => Dialog(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: <Widget>[
                              Text(DashboardStrings.screenshotViewer, style: Theme.of(context).textTheme.titleLarge),
                              const Spacer(),
                              const Text(DashboardStrings.zoomOriginalSize),
                              IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: InteractiveViewer(
                            minScale: 0.25,
                            maxScale: 6,
                            child: Center(child: Image.memory(validScreenshot.pngBytes, fit: BoxFit.contain, errorBuilder: _imageErrorBuilder)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              OutlinedButton(onPressed: null, child: Text(DashboardStrings.saveImage)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Image.memory(validScreenshot.pngBytes, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: _imageErrorBuilder),
            ),
    );
  }
}
