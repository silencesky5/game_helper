import '../action/device_action.dart';
import '../core/result.dart';
import 'workflow_runtime.dart';
import 'workflow_step.dart';

/// Executes workflow steps and device actions against runtime dependencies.
class StepExecutor {
  /// Creates a workflow step executor.
  const StepExecutor();

  /// Executes [step] with the provided [runtime].
  Future<void> execute(WorkflowStep step, WorkflowRuntime runtime) async {
    await step.execute(runtime);
  }

  /// Executes a device [action] without exposing device services to workflows.
  Future<Result<void>> executeAction(DeviceAction action, ActionContext context) {
    return action.execute(context);
  }
}
