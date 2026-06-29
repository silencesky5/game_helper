import '../../automation/models/task_result.dart';
import 'automation_context.dart';

/// Game-agnostic module contract for dashboard-driven automation logic.
///
/// New game behavior should be introduced by adding task modules that implement
/// this interface. The automation engine can execute tasks through this stable
/// contract without knowing game-specific scene, OCR, or image-template details.
abstract class AutomationTask {
  /// Stable module id used by persisted task logic configuration.
  String get id;

  /// Human-readable task name shown in task logic UIs and logs.
  String get name;

  /// Whether this task is enabled for the current run.
  bool get enabled;

  /// Executes one module against the shared automation runtime context.
  Future<TaskResult> execute(AutomationContext context);
}
