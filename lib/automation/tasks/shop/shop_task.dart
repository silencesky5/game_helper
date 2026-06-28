import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Shop task plugin.
class ShopTask extends GameTask {
  /// Creates the Shop task.
  const ShopTask() : super(id: 'shop', name: 'Shop', priority: 70);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    context.log('Claim free shop items');
    return const TaskResult.success('Shop completed');
  }
}
