import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents an intended wait duration.
class WaitStep extends WorkflowStep {
  /// Intended wait duration in milliseconds.
  final int milliseconds;

  /// Creates an immutable wait workflow step.
  const WaitStep({
    required super.id,
    required this.milliseconds,
  }) : super(type: 'wait');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {}
}
