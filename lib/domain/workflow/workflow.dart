import 'workflow_step.dart';

/// Describes a workflow configuration in the domain layer.
class Workflow {
  /// Unique workflow identifier.
  final String id;

  /// Human-readable workflow name.
  final String name;

  /// Ordered workflow steps.
  final List<WorkflowStep> steps;

  /// Creates a workflow definition.
  const Workflow({
    required this.id,
    required this.name,
    required this.steps,
  });
}
