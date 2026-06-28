import 'workflow_runtime.dart';
import 'workflow_step.dart';

/// Executes workflow steps against a workflow runtime.
class StepExecutor {
  /// Creates a workflow step executor.
  const StepExecutor();

  /// Executes [step] with the provided [runtime].
  Future<void> execute(WorkflowStep step, WorkflowRuntime runtime) async {
    await step.execute(runtime);
  }
}
