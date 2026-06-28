import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that delays execution for a duration.
class DelayStep extends WorkflowStep {
  /// Delay duration in milliseconds.
  final int milliseconds;

  /// Creates an immutable delay workflow step.
  const DelayStep({
    required super.id,
    required this.milliseconds,
  }) : super(type: 'delay');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
  }
}
