import 'package:flutter/material.dart';

import '../../domain/automation/automation_session.dart';
import '../../domain/automation/automation_state.dart';
import '../../domain/device/device.dart';
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
                      children: sessions.map(_DeviceCard.new).toList(growable: false),
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
  const _DeviceCard(this.session);

  final AutomationSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
          ],
        ),
      ),
    );
  }
}
