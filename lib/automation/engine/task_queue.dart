import 'game_task.dart';

/// FIFO queue of tasks waiting to run.
class TaskQueue {
  /// Creates a queue from sorted tasks.
  TaskQueue(Iterable<GameTask> tasks) : _tasks = List<GameTask>.of(tasks);

  final List<GameTask> _tasks;

  /// Whether there are waiting tasks.
  bool get notEmpty => _tasks.isNotEmpty;

  /// Snapshot of waiting tasks.
  List<GameTask> get pending => List<GameTask>.unmodifiable(_tasks);

  /// Removes and returns the next task.
  GameTask takeFirst() => _tasks.removeAt(0);
}
