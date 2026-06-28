import 'package:flutter/material.dart';

import '../../domain/automation/automation_session.dart';
import '../../domain/automation/automation_state.dart';
import '../../domain/decision/decision_state.dart';
import '../../domain/screenshot/device_screenshot.dart';
import 'automation_controller.dart';
import 'widgets/start_button.dart';

/// Dashboard entry point for the desktop automation console.
class DashboardPage extends StatefulWidget {
  /// Creates the dashboard page.
  const DashboardPage({super.key, this.controller});

  /// Controller used to start automation.
  final AutomationController? controller;

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
        title: const Text('Game Helper Desktop Console'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_controller.running ? 'Running pipeline...' : 'Ready')),
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: 0,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.extension), label: Text('Plugins')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ADBSettingsCard(controller: _controller),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Text('Device Sessions', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _controller.detecting ? null : _controller.initializeDesktopConsole,
                        icon: const Icon(Icons.refresh),
                        label: Text(_controller.detecting ? 'Detecting...' : 'Detect Devices'),
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
                        : GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.85,
                            children: sessions
                                .map((AutomationSession session) => _DeviceCard(session: session, controller: _controller))
                                .toList(growable: false),
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
}


class _ADBSettingsCard extends StatelessWidget {
  const _ADBSettingsCard({required this.controller});

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
            Text('ADB Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('ADB Path: ${adbManager.adbPath ?? 'Not discovered'}'),
            Text('ADB Version: ${adbManager.adbVersion ?? 'Unknown'}'),
            Text('Connection Status: ${adbManager.connectionStatus}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _showADBPathDialog(context),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse...'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.testADBConnection,
                  icon: const Icon(Icons.cable),
                  label: const Text('Test Connection'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.rescanADB,
                  icon: const Icon(Icons.search),
                  label: const Text('Rescan'),
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
        title: const Text('ADB Path'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'adb.exe path',
            hintText: r'C:\LDPlayer\LDPlayer9\adb.exe',
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(textController.text), child: const Text('Save')),
        ],
      ),
    );
    textController.dispose();
    if (path != null && path.trim().isNotEmpty) {
      await controller.setADBPath(path);
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
            detecting ? 'Detecting LDPlayer instances through ADB...' : 'No ADB devices detected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Start LDPlayer and ensure adb devices lists each emulator before launching automation.'),
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
        Text('Runtime Logs', style: Theme.of(context).textTheme.titleMedium),
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
                ? const Text('Waiting for desktop console events...')
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ScreenshotPreview(screenshot: screenshot),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(session.device.name, style: Theme.of(context).textTheme.titleLarge),
                  Text(session.device.id, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text('Device Status: ${session.device.status.name}'),
                  Text('Android Version: ${session.device.androidVersion}'),
                  Text('Resolution: ${session.device.resolution}'),
                  Text('Manufacturer: ${session.device.manufacturer}'),
                  Text('Model: ${session.device.model}'),
                  Text('Current Plugin: ${session.plugin?.name ?? 'Mine Journey'}'),
                  Text('Current Goal: ${decision?.currentGoal ?? 'Device Monitor'}'),
                  Text('Runtime: ${session.startedAt == null ? '00:00:00' : DateTime.now().difference(session.startedAt!).toString().split('.').first}'),
                  Text('Current State: ${session.state == AutomationState.idle ? 'idle' : session.state.name}'),
                  Text('Current Step: ${session.currentStep}'),
                  Text('Screenshot Status: ${screenshot == null ? 'waiting for live frame' : 'live'}'),
                  Text('Last Update: ${screenshot?.updatedAt.toLocal().toString().split('.').first ?? 'Never'}'),
                  const Divider(height: 16),
                  Text('Device Monitor', style: Theme.of(context).textTheme.titleSmall),
                  Text('Current Decision: ${decision?.currentDecision ?? 'Waiting'}'),
                  Text('Current Action: ${decision?.currentAction ?? 'None'}'),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      OutlinedButton(onPressed: () => controller.captureScreenshot(session), child: const Text('Screenshot')),
                      OutlinedButton(onPressed: () => controller.tapTest(session), child: const Text('Tap Test')),
                      OutlinedButton(onPressed: () => controller.swipeTest(session), child: const Text('Swipe Test')),
                      OutlinedButton(onPressed: () => controller.restartSession(session), child: const Text('Restart Session')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
          ? const Center(child: Text('No Screenshot'))
          : Image.memory(screenshot!.pngBytes, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}
