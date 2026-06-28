import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Stone task plugin.
class StoneTask extends GameTask {
  /// Creates the Stone task.
  const StoneTask() : super(id: 'stone', name: 'Stone', priority: 60);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    context.log('Combine available stones');
    return const TaskResult.success('Stone completed');
  }
}
