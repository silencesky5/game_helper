import 'package:flutter/material.dart';

import '../../domain/automation/automation_session.dart';
import '../../domain/automation/automation_state.dart';
import '../../domain/device/device.dart';
import '../../domain/screenshot/device_screenshot.dart';
import '../../domain/vision/vision_types.dart';
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
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AutomationSession> sessions = _controller.sessions.isEmpty ? _mockSessions : _controller.sessions;

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
                  Row(
                    children: <Widget>[
                      Text('Device Sessions', style: Theme.of(context).textTheme.headlineMedium),
                      const Spacer(),
                      StartButton(onPressed: _controller.running ? null : _controller.start),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 2.7,
                      children: sessions
                          .map((AutomationSession session) => _DeviceCard(session: session, controller: _controller))
                          .toList(growable: false),
                    ),
                  ),
                  const Divider(),
                  const Text('Console Logger: engine events are printed to the Dart console.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AutomationSession> get _mockSessions {
    return const <AutomationSession>[
      AutomationSession(id: 'Session 1', device: Device(id: 'demo-1', name: 'LDPlayer1', status: DeviceStatus.online), currentStep: 'Idle'),
      AutomationSession(id: 'Session 2', device: Device(id: 'demo-2', name: 'LDPlayer2', status: DeviceStatus.online), currentStep: 'Idle'),
      AutomationSession(id: 'Session 3', device: Device(id: 'demo-3', name: 'LDPlayer3', status: DeviceStatus.offline), currentStep: 'Idle'),
      AutomationSession(id: 'Session 4', device: Device(id: 'demo-4', name: 'LDPlayer4', status: DeviceStatus.online), currentStep: 'Idle'),
    ];
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.session, required this.controller});

  final AutomationSession session;
  final AutomationController controller;

  @override
  Widget build(BuildContext context) {
    final DeviceScreenshot? screenshot = controller.screenshotRepository.latest(session.device.id);
    final VisionResult? vision = controller.visionRepository.lastAnalysis(session.device.id);
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
                  Text('${session.id} → ${session.device.name}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Online Status: ${session.device.status.name}'),
                  Text('Current Plugin: ${session.plugin?.name ?? 'Mine Journey'}'),
                  Text('Current Workflow: ${session.workflow?.name ?? 'Dummy Workflow'}'),
                  Text('Runtime: ${session.startedAt == null ? '00:00:00' : DateTime.now().difference(session.startedAt!).toString().split('.').first}'),
                  Text('Current Step: ${session.currentStep}'),
                  Text('Session State: ${session.state == AutomationState.idle ? 'idle' : session.state.name}'),
                  Text('Screenshot Status: ${screenshot == null ? 'placeholder' : 'live'}'),
                  Text('Last Update: ${screenshot?.updatedAt.toLocal().toString().split('.').first ?? 'Never'}'),
                  const Divider(height: 16),
                  Text('Vision Panel', style: Theme.of(context).textTheme.titleSmall),
                  Text('Current State: ${vision?.currentState.name ?? 'unknown'}'),
                  Text('Last Vision Time: ${vision?.timestamp.toLocal().toString().split('.').first ?? 'Never'}'),
                  Text('Match Count: ${vision?.matchCount ?? 0}'),
                  Text('Detection Status: ${vision?.detectionStatus ?? 'waiting'}'),
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
