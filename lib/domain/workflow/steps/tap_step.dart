import '../../logger/logger.dart';
import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that represents a tap command at a coordinate.
class TapStep extends WorkflowStep {
  /// Horizontal tap coordinate.
  final int x;

  /// Vertical tap coordinate.
  final int y;

  /// Creates an immutable tap workflow step.
  const TapStep({
    required super.id,
    required this.x,
    required this.y,
  }) : super(type: 'tap');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {
    final context = runtime.context;

    if (context == null) {
      throw StateError('WorkflowRuntime requires an AutomationContext.');
    }

    context.loggerService.log(LogLevel.info, 'Executing TapStep');
    await context.deviceManager.deviceService.tap(x, y);
  }
}
