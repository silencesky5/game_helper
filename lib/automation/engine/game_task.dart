import '../models/task_context.dart';
import '../models/task_result.dart';

/// Base class for every game-specific task plugin.
abstract class GameTask {
  /// Creates a game task.
  const GameTask({required this.id, required this.name, required this.priority});

  /// Stable task id used in profiles and logs.
  final String id;

  /// Human-readable task name.
  final String name;

  /// Higher priority tasks run first.
  final int priority;

  /// Executes the task against the provided context.
  Future<TaskResult> execute(TaskContext context);
}
