import 'workflow_step.dart';

/// Immutable workflow definition used by the workflow engine.
class Workflow {
  /// Unique workflow identifier.
  final String id;

  /// Human-readable workflow name.
  final String name;

  /// Human-readable workflow description.
  final String description;

  /// Workflow definition version.
  final String version;

  /// Ordered workflow steps to execute.
  final List<WorkflowStep> steps;

  /// Creates an immutable workflow definition.
  const Workflow({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.steps,
  });
}
