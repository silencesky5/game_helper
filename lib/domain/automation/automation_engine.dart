import '../logger/logger_service.dart';
import '../plugin/plugin.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_runtime.dart';
import 'automation_context.dart';
import 'automation_session.dart';
import 'automation_state.dart';

/// Platform automation orchestrator.
///
/// The engine owns no plugin or workflow runtime state. It only creates and
/// transitions immutable [AutomationSession] instances.
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

  /// Marks [session] as running without executing workflow steps.
  AutomationSession start(AutomationSession session) {
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
