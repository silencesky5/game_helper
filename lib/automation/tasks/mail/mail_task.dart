import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Mail task plugin.
class MailTask extends GameTask {
  /// Creates the Mail task.
  const MailTask() : super(id: 'mail', name: 'Mail', priority: 80);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    context.log('Claim all mailbox rewards');
    return const TaskResult.success('Mail completed');
  }
}
