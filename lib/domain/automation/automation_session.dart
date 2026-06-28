import '../logger/logger_service.dart';
import '../plugin/plugin.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_runtime.dart';
import 'automation_state.dart';

/// Immutable runtime state for a single automation session.
class AutomationSession {
  /// Current plugin associated with the session, if one has been selected.
  final Plugin? plugin;

  /// Current workflow associated with the session, if one has been selected.
  final Workflow? workflow;

  /// Workflow runtime state associated with the session, if one exists.
  final WorkflowRuntime? workflowRuntime;

  /// Current automation lifecycle state.
  final AutomationState state;

  /// Logger associated with this session.
  final LoggerService? logger;

  /// Creates immutable automation session state.
  const AutomationSession({
    this.plugin,
    this.workflow,
    this.workflowRuntime,
    this.state = AutomationState.idle,
    this.logger,
  });

  /// Creates a new session with selected fields replaced.
  AutomationSession copyWith({
    Plugin? plugin,
    Workflow? workflow,
    WorkflowRuntime? workflowRuntime,
    AutomationState? state,
    LoggerService? logger,
  }) {
    return AutomationSession(
      plugin: plugin ?? this.plugin,
      workflow: workflow ?? this.workflow,
      workflowRuntime: workflowRuntime ?? this.workflowRuntime,
      state: state ?? this.state,
      logger: logger ?? this.logger,
    );
  }
}
