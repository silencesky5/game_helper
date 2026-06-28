import '../device/device.dart';
import '../logger/logger.dart';
import '../plugin/plugin.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_runtime.dart';
import 'automation_context.dart';
import 'automation_session.dart';
import 'automation_state.dart';

/// Platform automation orchestrator.
///
/// The engine is the only orchestrator connecting device discovery, sessions,
/// plugin loading, workflow execution, and engine logging.
class AutomationEngine {
  /// Creates an automation engine from explicit domain dependencies.
  const AutomationEngine({required this.context});

  /// Domain services available to the automation runtime.
  final AutomationContext context;

  /// Creates a new idle automation session for [device].
  AutomationSession createSession(Device device) {
    return context.sessionManager.createSession(device);
  }

  /// Runs the Sprint 1 end-to-end execution pipeline for [pluginId].
  Future<List<AutomationSession>> start(String pluginId) async {
    context.loggerService.log(LogLevel.info, 'Detecting ADB devices');
    final List<Device> devices = await context.deviceManager.detectDevices();

    if (context.pluginManager.plugins.isEmpty) {
      await context.pluginManager.initialize();
    }

    final Plugin? plugin = context.pluginManager.getPlugin(pluginId);
    if (plugin == null) {
      throw StateError('Plugin not found: $pluginId');
    }
    context.loggerService.log(LogLevel.info, 'Loaded plugin: ${plugin.name}');

    final List<Device> demoDevices = devices.isEmpty ? _fallbackDemoDevices() : devices;
    final List<AutomationSession> sessions = <AutomationSession>[];

    for (final Device device in demoDevices) {
      final AutomationSession session = createSession(device);
      final Workflow workflow = await context.pluginManager.getWorkflow(plugin);
      final WorkflowRuntime runtime = WorkflowRuntime(context: context);
      final AutomationSession runningSession = startSession(
        session.copyWith(
          plugin: plugin,
          workflow: workflow,
          workflowRuntime: runtime,
          startedAt: DateTime.now(),
          currentStep: workflow.steps.isEmpty ? 'No steps' : workflow.steps.first.id,
        ),
      );
      context.sessionManager.updateSession(runningSession);
      sessions.add(runningSession);

      context.workflowEngine.runtime.context = context;
      context.loggerService.log(LogLevel.info, 'Starting ${runningSession.id} on ${device.name}');
      await context.workflowEngine.execute(workflow);
      context.sessionManager.updateSession(
        runningSession.copyWith(state: AutomationState.completed, currentStep: 'Finished'),
      );
      context.loggerService.log(LogLevel.info, '${runningSession.id} finished');
    }

    return context.sessionManager.sessions;
  }

  /// Marks [session] as running without executing workflow steps.
  AutomationSession startSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.running);
  }

  /// Marks [session] as paused without operating devices or workflow steps.
  AutomationSession pauseSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.paused);
  }

  /// Marks [session] as running without executing workflow steps.
  AutomationSession resumeSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.running);
  }

  /// Marks [session] as stopped without operating devices or workflow steps.
  AutomationSession stopSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.stopped);
  }

  List<Device> _fallbackDemoDevices() {
    return const <Device>[
      Device(id: 'demo-ldplayer-1', name: 'LDPlayer1', status: DeviceStatus.online),
      Device(id: 'demo-ldplayer-2', name: 'LDPlayer2', status: DeviceStatus.online),
      Device(id: 'demo-ldplayer-3', name: 'LDPlayer3', status: DeviceStatus.offline),
      Device(id: 'demo-ldplayer-4', name: 'LDPlayer4', status: DeviceStatus.online),
    ];
  }
}
