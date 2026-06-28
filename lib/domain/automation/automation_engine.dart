import '../logger/logger.dart';
import '../logger/logger_service.dart';
import '../plugin/plugin.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_runtime.dart';
import 'automation_context.dart';
import 'automation_session.dart';
import 'automation_state.dart';

/// Platform automation orchestrator.
///
/// The engine connects plugin loading, workflow execution, and device services
/// without knowing concrete workflow step implementations.
class AutomationEngine {
  /// Domain services available to the automation runtime.
  final AutomationContext context;

  /// Creates an automation engine from explicit domain dependencies.
  const AutomationEngine({required this.context});

  /// Creates a new idle automation session.
  AutomationSession createSession({
    Plugin? plugin,
    Workflow? workflow,
    WorkflowRuntime? workflowRuntime,
    LoggerService? logger,
  }) {
    return AutomationSession(
      plugin: plugin,
      workflow: workflow,
      workflowRuntime: workflowRuntime,
      logger: logger,
    );
  }

  /// Starts the first end-to-end execution pipeline for [pluginId].
  Future<void> start(String pluginId) async {
    context.loggerService.log(LogLevel.info, 'Automation Started');

    if (context.pluginManager.plugins.isEmpty) {
      await context.pluginManager.initialize();
    }

    final Plugin? plugin = context.pluginManager.getPlugin(pluginId);

    if (plugin == null) {
      throw StateError('Plugin not found: $pluginId');
    }

    final Workflow workflow = await context.pluginManager.getWorkflow(plugin);
    context.loggerService.log(LogLevel.info, 'Workflow Loaded');

    context.workflowEngine.runtime.context = context;
    await context.workflowEngine.execute(workflow);

    context.loggerService.log(LogLevel.info, 'Automation Finished');
  }

  /// Marks [session] as running without executing workflow steps.
  AutomationSession startSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.running);
  }

  /// Marks [session] as paused without operating devices or workflow steps.
  AutomationSession pause(AutomationSession session) {
    return session.copyWith(state: AutomationState.paused);
  }

  /// Marks [session] as running without executing workflow steps.
  AutomationSession resume(AutomationSession session) {
    return session.copyWith(state: AutomationState.running);
  }

  /// Marks [session] as stopped without operating devices or workflow steps.
  AutomationSession stop(AutomationSession session) {
    return session.copyWith(state: AutomationState.stopped);
  }
}
