import '../device/device.dart';
import '../logger/logger_service.dart';
import '../plugin/plugin.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_runtime.dart';
import 'automation_state.dart';

/// Immutable runtime state for a single automation session.
class AutomationSession {
  /// Creates immutable automation session state.
  const AutomationSession({
    required this.id,
    required this.device,
    this.plugin,
    this.workflow,
    this.workflowRuntime,
    this.state = AutomationState.idle,
    this.logger,
    this.startedAt,
    this.currentStep = 'Idle',
  });

  /// Unique session identifier.
  final String id;

  /// Android device assigned to this session.
  final Device device;

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

  /// Session start timestamp.
  final DateTime? startedAt;

  /// Current step name shown in the desktop console.
  final String currentStep;

  /// Creates a new session with selected fields replaced.
  AutomationSession copyWith({
    String? id,
    Device? device,
    Plugin? plugin,
    Workflow? workflow,
    WorkflowRuntime? workflowRuntime,
    AutomationState? state,
    LoggerService? logger,
    DateTime? startedAt,
    String? currentStep,
  }) {
    return AutomationSession(
      id: id ?? this.id,
      device: device ?? this.device,
      plugin: plugin ?? this.plugin,
      workflow: workflow ?? this.workflow,
      workflowRuntime: workflowRuntime ?? this.workflowRuntime,
      state: state ?? this.state,
      logger: logger ?? this.logger,
      startedAt: startedAt ?? this.startedAt,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
