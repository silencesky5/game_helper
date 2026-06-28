import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents an intended delay duration.
class DelayStep extends WorkflowStep {
  /// Intended delay duration in milliseconds.
  final int milliseconds;

  /// Creates an immutable delay workflow step.
  const DelayStep({
    required super.id,
    required this.milliseconds,
  }) : super(type: 'delay');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {}
}
