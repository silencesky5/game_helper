import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Repair task plugin.
class RepairTask extends GameTask {
  /// Creates the Repair task.
  const RepairTask() : super(id: 'repair', name: 'Repair', priority: 40);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    if (!context.stateManager.equipmentBroken()) {
      return const TaskResult.skipped('Equipment is healthy');
    }
    context.log('Repair all equipment');
    return const TaskResult.success('Repair completed');
  }
}
