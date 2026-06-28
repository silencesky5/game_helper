import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents a swipe command between two coordinates.
class SwipeStep extends WorkflowStep {
  /// Horizontal swipe start coordinate.
  final int startX;

  /// Vertical swipe start coordinate.
  final int startY;

  /// Horizontal swipe end coordinate.
  final int endX;

  /// Vertical swipe end coordinate.
  final int endY;

  /// Intended swipe duration in milliseconds.
  final int duration;

  /// Creates an immutable swipe workflow step.
  const SwipeStep({
    required super.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.duration,
  }) : super(type: 'swipe');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {}
}
