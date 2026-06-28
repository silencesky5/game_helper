import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents a conditional branch definition.
class IfStep extends WorkflowStep {
  /// Condition expression identifier for future evaluation.
  final String condition;

  /// Creates an immutable conditional workflow step.
  const IfStep({
    required super.id,
    required this.condition,
  }) : super(type: 'if');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {}
}
