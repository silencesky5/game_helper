import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents a loop count definition.
class LoopStep extends WorkflowStep {
  /// Intended number of loop iterations.
  final int count;

  /// Creates an immutable loop workflow step.
  const LoopStep({
    required super.id,
    required this.count,
  }) : super(type: 'loop');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {}
}
