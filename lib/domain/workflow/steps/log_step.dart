import '../../logger/logger.dart';
import '../workflow_runtime.dart';
import '../workflow_step.dart';

/// Workflow step that writes an engine event to the console logger.
class LogStep extends WorkflowStep {
  /// Message to log when this step executes.
  final String message;

  /// Creates an immutable log workflow step.
  const LogStep({
    required super.id,
    required this.message,
  }) : super(type: 'log');

  @override
  Future<void> execute(WorkflowRuntime runtime) async {
    final context = runtime.context;
    if (context == null) {
      throw StateError('WorkflowRuntime requires an AutomationContext.');
    }
    context.loggerService.log(LogLevel.info, message);
  }
}
