import 'workflow_runtime.dart';

/// Defines a single executable workflow step in the domain layer.
abstract class WorkflowStep {
  /// Unique step identifier within a workflow.
  final String id;

  /// Registered workflow step type identifier.
  final String type;

  /// Creates a workflow step with an [id] and [type].
  const WorkflowStep({
    required this.id,
    required this.type,
  });

  /// Executes this step against the provided workflow [runtime].
  Future<void> execute(WorkflowRuntime runtime);
}
