import 'automation_config.dart';
import '../device/device.dart';
import '../logger/logger_service.dart';
import '../plugin/plugin.dart';
import '../plugin/game_profile.dart';
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
    this.character = const CharacterProfile.notLoggedIn(),
    this.taskProfile,
    this.automationConfig,
    this.state = AutomationState.idle,
    this.logger,
    this.startedAt,
    this.currentStep = 'Idle',
    this.nextStep = 'Waiting',
    this.currentScene = 'Unknown',
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

  /// Character detected by the current plugin.
  final CharacterProfile character;

  /// Selected task profile for this device/character runtime.
  final TaskProfile? taskProfile;

  /// Device-owned automation logic config.
  final AutomationConfig? automationConfig;

  /// Current automation lifecycle state.
  final AutomationState state;

  /// Logger associated with this session.
  final LoggerService? logger;

  /// Session start timestamp.
  final DateTime? startedAt;

  /// Current step name shown in the desktop console.
  final String currentStep;

  /// Next launch/workflow step shown in the desktop console.
  final String nextStep;

  /// Last detected scene shown in the desktop console.
  final String currentScene;

  /// Creates a new session with selected fields replaced.
  AutomationSession copyWith({
    String? id,
    Device? device,
    Plugin? plugin,
    Workflow? workflow,
    WorkflowRuntime? workflowRuntime,
    CharacterProfile? character,
    TaskProfile? taskProfile,
    AutomationConfig? automationConfig,
    AutomationState? state,
    LoggerService? logger,
    DateTime? startedAt,
    String? currentStep,
    String? nextStep,
    String? currentScene,
  }) {
    return AutomationSession(
      id: id ?? this.id,
      device: device ?? this.device,
      plugin: plugin ?? this.plugin,
      workflow: workflow ?? this.workflow,
      workflowRuntime: workflowRuntime ?? this.workflowRuntime,
      character: character ?? this.character,
      taskProfile: taskProfile ?? this.taskProfile,
      automationConfig: automationConfig ?? this.automationConfig,
      state: state ?? this.state,
      logger: logger ?? this.logger,
      startedAt: startedAt ?? this.startedAt,
      currentStep: currentStep ?? this.currentStep,
      nextStep: nextStep ?? this.nextStep,
      currentScene: currentScene ?? this.currentScene,
    );
  }
}
