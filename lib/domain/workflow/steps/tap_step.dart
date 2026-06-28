import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Reserved Sprint 2 workflow step for a tap command at a coordinate.
class TapStep extends WorkflowStep {
  /// Horizontal tap coordinate.
  final int x;

  /// Vertical tap coordinate.
  final int y;

  /// Creates an immutable tap workflow step definition.
  const TapStep({
    required super.id,
    required this.x,
    required this.y,
  }) : super(type: 'tap');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {
    throw UnsupportedError('TapStep is planned for Sprint 2 and is not executable in Sprint 1.');
  }
}
