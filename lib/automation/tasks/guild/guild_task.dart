import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Guild task plugin.
class GuildTask extends GameTask {
  /// Creates the Guild task.
  const GuildTask() : super(id: 'guild', name: 'Guild', priority: 10);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    context.log('Complete guild daily tasks and claim rewards');
    return const TaskResult.success('Guild completed');
  }
}
