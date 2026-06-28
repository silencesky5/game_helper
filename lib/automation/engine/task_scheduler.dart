import 'automation_profile.dart';
import 'game_task.dart';
import 'task_queue.dart';

/// Builds prioritized queues from profile-enabled task plugins.
class TaskScheduler {
  /// Creates a scheduler.
  const TaskScheduler();

  /// Skips disabled tasks and sorts the rest by descending priority.
  TaskQueue createQueue(AutomationProfile profile, Iterable<GameTask> tasks) {
    final scheduled = tasks.where((task) => profile.isEnabled(task.id)).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return TaskQueue(scheduled);
  }
}
