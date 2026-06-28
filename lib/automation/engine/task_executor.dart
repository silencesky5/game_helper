import '../models/task_context.dart';
import '../models/task_result.dart';
import 'popup_manager.dart';
import 'task_queue.dart';

/// Executes queued tasks with a bounded retry policy.
class TaskExecutor {
  /// Creates a task executor.
  const TaskExecutor({
    this.maxRetries = 3,
    this.popupManager = const PopupManager(),
  });

  /// Maximum retries before stopping the queue.
  final int maxRetries;

  /// Global popup checker executed before every task.
  final PopupManager popupManager;

  /// Runs tasks until completion or an unrecoverable failure.
  Future<List<TaskResult>> execute(TaskQueue queue, TaskContext context) async {
    final results = <TaskResult>[];
    while (queue.notEmpty) {
      final task = queue.takeFirst();
      context.log('${task.name} Start');
      final popupResult = await popupManager.checkAndHandle(context);
      if (popupResult.status != TaskResultStatus.skipped) {
        results.add(popupResult);
        context.log('Popup ${popupResult.status.name}: ${popupResult.message}');
        if (!popupResult.canContinue) {
          break;
        }
      }
      var attempt = 0;
      TaskResult result;
      do {
        result = await task.execute(context);
        results.add(result);
        if (result.canContinue) {
          context.log('${task.name} ${result.status.name}');
          break;
        }
        attempt += 1;
        context.log(
          '${task.name} ${result.status.name}; retry $attempt/$maxRetries',
        );
      } while (attempt <= maxRetries && result.shouldRetry);

      if (!result.canContinue && attempt > maxRetries) {
        context.log('${task.name} Stop after $maxRetries retries');
        break;
      }
    }
    return results;
  }
}
