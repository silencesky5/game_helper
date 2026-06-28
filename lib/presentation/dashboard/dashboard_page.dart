import 'package:flutter/material.dart';

import '../../domain/automation/automation_session.dart';
import '../../domain/automation/automation_state.dart';
import '../../domain/decision/decision_state.dart';
import '../../domain/plugin/game_profile.dart';
import '../../domain/screenshot/device_screenshot.dart';
import '../../app/localization/l10n_extension.dart';
import '../../app/localization/language_manager.dart';
import 'automation_controller.dart';
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
              const NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Statistics')),
              const NavigationRailDestination(icon: Icon(Icons.article), label: Text('Logs')),
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
                      Text(context.l10n.deviceSessions, style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _controller.detecting ? null : _controller.initializeDesktopConsole,
                        icon: const Icon(Icons.refresh),
                        label: Text(_controller.detecting ? context.l10n.detecting : context.l10n.detectDevices),
                      ),
                      const SizedBox(width: 12),
                      StartButton(onPressed: _controller.running || sessions.isEmpty ? null : _controller.start),
                    ],
                  ),
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
    if (mounted) setState(() {});
  }

  void _openNavigationDestination(BuildContext context, int index) {
    if (index == 1) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PluginsPage()));
    } else if (index == 4) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettingsPage(controller: _controller, languageManager: widget.languageManager)));
    }
  }
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
    final DecisionStatus? decision = controller.decisionRepository.statusFor(session.device.id);
    final String pluginName = session.plugin?.displayName ?? '未指定';
    final String pluginVersion = session.plugin?.version ?? 'N/A';
    final String characterLevel = session.character.level == null ? '' : ' / ${session.character.level}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(session.device.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('$pluginName  v$pluginVersion', style: Theme.of(context).textTheme.titleMedium),
                      Text('角色：${session.character.displayName}$characterLevel'),
                      Text('Task Profile：${session.taskProfile?.name ?? '未指定'}'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Rename device',
                  onPressed: () => _showRenameDialog(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ScreenshotPreview(screenshot: screenshot),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        value: session.plugin?.id ?? 'unassigned',
                        decoration: const InputDecoration(labelText: '遊戲', isDense: true),
                        items: controller.availablePlugins
                            .map((plugin) => DropdownMenuItem<String>(value: plugin.id, child: Text(plugin.displayName)))
                            .toList(growable: false),
                        onChanged: (String? pluginId) {
                          if (pluginId != null) controller.assignPlugin(session, pluginId);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: session.taskProfile?.id,
                        decoration: const InputDecoration(labelText: 'Task Profile', isDense: true),
                        items: (session.plugin?.implementation?.createTaskProfiles() ?? const <TaskProfile>[])
                            .map((profile) => DropdownMenuItem<String>(value: profile.id, child: Text(profile.name)))
                            .toList(growable: false),
                        onChanged: (String? profileId) {
                          if (profileId != null) controller.assignTaskProfile(session, profileId);
                        },
                      ),
                      const SizedBox(height: 12),
                      _RuntimeMonitor(session: session, decision: decision),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ActionGroups(session: session, controller: controller, onPluginSettings: () => _showPluginSettings(context), onDeviceInfo: () => _showDeviceInfoDialog(context, screenshot)),
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
        title: const Text('Device Name'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Device #1'),
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

  Future<void> _showPluginSettings(BuildContext context) async {
    final plugin = session.plugin;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('⚙ Plugin Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Plugin Internal Name  ${plugin?.name ?? 'N/A'}'),
            Text('Plugin Version  ${plugin?.version ?? 'N/A'}'),
            Text('Plugin Author  ${plugin?.author ?? 'N/A'}'),
            Text('Plugin Log  See Runtime Logs'),
            const Text('Debug  Enabled from dashboard actions'),
            const Text('Reload Plugin  Coming soon'),
            const Text('OCR Test  Coming soon'),
            const Text('Image Test  Coming soon'),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showDeviceInfoDialog(BuildContext context, DeviceScreenshot? screenshot) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('裝置資訊'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InfoRow(label: 'Android Version', value: session.device.androidVersion),
              _InfoRow(label: 'Resolution', value: session.device.resolution),
              _InfoRow(label: 'Brand', value: session.device.manufacturer),
              _InfoRow(label: 'Model', value: session.device.model),
              _InfoRow(label: 'Serial', value: session.device.id),
              _InfoRow(label: 'ADB', value: session.device.status.name),
              const _InfoRow(label: 'CPU', value: 'N/A'),
              const _InfoRow(label: 'Memory', value: 'N/A'),
              _InfoRow(label: 'Plugin Version', value: session.plugin?.version ?? 'N/A'),
              _InfoRow(label: 'Last Update', value: screenshot?.updatedAt.toLocal().toString().split('.').first ?? context.l10n.never),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _RuntimeMonitor extends StatelessWidget {
  const _RuntimeMonitor({required this.session, required this.decision});

  final AutomationSession session;
  final DecisionStatus? decision;

  @override
  Widget build(BuildContext context) {
    final runtime = session.startedAt == null ? '00:00:00' : DateTime.now().difference(session.startedAt!).toString().split('.').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Runtime', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _InfoRow(label: '目前任務', value: decision?.currentGoal ?? context.l10n.deviceMonitor),
        _InfoRow(label: '下一步', value: decision?.currentAction ?? context.l10n.waiting),
        _InfoRow(label: '執行時間', value: runtime),
        _StatusRow(state: session.state),
        _InfoRow(label: '錯誤', value: context.l10n.none),
      ],
    );
  }
}

class _ActionGroups extends StatelessWidget {
  const _ActionGroups({required this.session, required this.controller, required this.onPluginSettings, required this.onDeviceInfo});

  final AutomationSession session;
  final AutomationController controller;
  final VoidCallback onPluginSettings;
  final VoidCallback onDeviceInfo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _ButtonCluster(children: <Widget>[
          OutlinedButton(onPressed: () => controller.captureScreenshot(session), child: Text(context.l10n.screenshot)),
          OutlinedButton(onPressed: () => controller.detectCharacter(session), child: const Text('Detect Character')),
          OutlinedButton(onPressed: onPluginSettings, child: const Text('⚙ Plugin Settings')),
        ]),
        _ButtonCluster(children: <Widget>[
          OutlinedButton(onPressed: () => controller.tapTest(session), child: Text(context.l10n.tapTest)),
          OutlinedButton(onPressed: () => controller.swipeTest(session), child: Text(context.l10n.swipeTest)),
        ]),
        _ButtonCluster(children: <Widget>[
          OutlinedButton(onPressed: () => controller.restartSession(session), child: Text(context.l10n.restartSession)),
          OutlinedButton(onPressed: onDeviceInfo, child: const Text('裝置資訊')),
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
      AutomationState.running => ('🟢 Running', Colors.green),
      AutomationState.paused => ('🟡 Waiting', Colors.amber),
      AutomationState.completed => ('🔵 Working', Colors.blue),
      AutomationState.failed => ('🔴 Error', Colors.red),
      AutomationState.stopped => ('⚫ Offline', Colors.grey),
      AutomationState.idle => ('🟡 Waiting', Colors.amber),
    };
    return _InfoRow(label: '目前狀態', value: label, valueColor: color);
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
    return Container(
      width: 150,
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: screenshot == null
          ? Center(child: Text(context.l10n.noScreenshot))
          : InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext dialogContext) => Dialog(
                  child: InteractiveViewer(child: Image.memory(screenshot!.pngBytes, fit: BoxFit.contain)),
                ),
              ),
              child: Image.memory(screenshot!.pngBytes, fit: BoxFit.cover, gaplessPlayback: true),
            ),
    );
  }
}
