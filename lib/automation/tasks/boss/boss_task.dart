import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Boss task plugin.
class BossTask extends GameTask {
  /// Creates the Boss task.
  const BossTask() : super(id: 'boss', name: 'Boss', priority: 20);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    context.log('Check world boss schedule and enter if open');
    return const TaskResult.success('Boss completed');
  }
}
