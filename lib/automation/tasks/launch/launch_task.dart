import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';
import '../login/login_task.dart';

/// Version-1 automation task that only launches GrowStone and stops at Home.
class LaunchTask extends GameTask {
  /// Creates the launch-only task.
  const LaunchTask({this.loginTask = const LoginTask()})
      : super(id: 'launch_task', name: 'Launch Game', priority: 100);

  /// Scene-first login implementation used by the launch workflow.
  final LoginTask loginTask;

  /// Executes the launch flow with the v1 retry policy.
  @override
  Future<TaskResult> execute(TaskContext context) async {
    for (var attempt = 1; attempt <= 3; attempt += 1) {
      context.log('LaunchTask attempt $attempt/3');
      final result = await loginTask.execute(context);
      if (result.status == TaskResultStatus.success) {
        return const TaskResult.success('Launch Complete');
      }
      context.log('LaunchTask retry: ${result.message}');
    }
    return const TaskResult.failed('Launch Failed');
  }
}
