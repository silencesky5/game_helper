import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Mine task plugin.
class MineTask extends GameTask {
  /// Creates the Mine task.
  const MineTask() : super(id: 'mine', name: 'Mine', priority: 30);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    if (!context.stateManager.isMining()) {
      context.log('Navigate to mine and start mining');
    }
    if (context.stateManager.inventoryFull()) {
      context.log('Inventory full; inventory task should run before mining continues');
    }
    return const TaskResult.success('Mine completed');
  }
}
