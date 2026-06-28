import 'step_executor.dart';
import 'workflow.dart';
import 'workflow_runtime.dart';
import 'workflow_step.dart';

/// Coordinates workflow execution through a runtime and step executor.
class WorkflowEngine {
  /// Runtime state used while executing workflows.
  final WorkflowRuntime runtime;

  /// Executor used to run individual workflow steps.
  final StepExecutor executor;

  /// Creates a workflow engine with optional runtime and executor overrides.
  WorkflowEngine({
    WorkflowRuntime? runtime,
    StepExecutor? executor,
  })  : runtime = runtime ?? WorkflowRuntime(),
        executor = executor ?? const StepExecutor();

  /// Starts the workflow engine lifecycle.
  void start() {}

  /// Stops the workflow engine lifecycle.
  void stop() {}

  /// Pauses the workflow engine lifecycle.
  void pause() {}

  /// Resumes the workflow engine lifecycle.
  void resume() {}

  /// Executes every step in [workflow] in declaration order.
  Future<void> execute(Workflow workflow) async {
    for (final WorkflowStep step in workflow.steps) {
      await executor.execute(step, runtime);
    }
  }
}
