import 'package:flutter/material.dart';

import 'automation_controller.dart';
import 'widgets/start_button.dart';

/// Dashboard entry point for the automation execution pipeline.
class DashboardPage extends StatefulWidget {
  /// Creates the dashboard page.
  const DashboardPage({
    super.key,
    this.controller,
  });

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Helper Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StartButton(
              onPressed: _controller.running ? null : _controller.start,
            ),
            if (_controller.running) ...<Widget>[
              const SizedBox(height: 16),
              const Text('Running...'),
            ],
          ],
        ),
      ),
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
