import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Sign task plugin.
class SignTask extends GameTask {
  /// Creates the Sign task.
  const SignTask() : super(id: 'sign', name: 'Sign', priority: 90);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    context.log('Open activity daily sign page');
    return const TaskResult.success('Sign completed');
  }
}
