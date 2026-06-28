import '../../engine/game_task.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Login task plugin.
class LoginTask extends GameTask {
  /// Creates the Login task.
  const LoginTask() : super(id: 'login', name: 'Login', priority: 100);

  @override
  Future<TaskResult> execute(TaskContext context) async {
    if (!context.stateManager.isLogin()) {
      await context.actionController.launchGame(context.emulator, 'game.package');
    }
    return const TaskResult.success('Login completed');
  }
}
