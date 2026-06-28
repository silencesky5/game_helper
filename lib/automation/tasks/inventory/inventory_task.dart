import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Inventory task plugin.
class InventoryTask extends GameTask {
  /// Creates the Inventory task.
  const InventoryTask() : super(id: 'inventory', name: 'Inventory', priority: 50);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    if (!context.stateManager.inventoryFull()) {
      return const TaskResult.skipped('Inventory is not full');
    }
    context.log('Sort inventory and confirm');
    return const TaskResult.success('Inventory completed');
  }
}
