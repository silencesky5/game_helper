import '../../engine/game_task.dart';
import '../../engine/image_detector.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';

/// Launches GrowStone from Android desktop and waits until gameplay can resume.
class LoginTask extends GameTask {
  /// Creates the GrowStone launch task.
  const LoginTask()
      : super(id: 'launch_growstone', name: 'Launch GrowStone', priority: 100);

  static const String growStonePackageName = 'com.superbox.aos.growstone';

  @override
  Future<TaskResult> execute(TaskContext context) async {
    final initialScene = await context.stateManager.detectScene();
    if (initialScene == Scene.home || await context.stateManager.isHomeScene()) {
      return const TaskResult.success('GrowStone home scene already detected');
    }

    if (initialScene != Scene.android &&
        !await context.stateManager.hasGrowStoneIcon()) {
      return const TaskResult.retry('GrowStone is not on Android desktop');
    }

    context.log('GrowStone icon detected on Android desktop');

    await context.actionController.launchGame(
      context.emulator,
      growStonePackageName,
    );

    final loaded = await context.actionController.waitSceneChange(() async {
      final scene = await context.stateManager.detectScene();
      if (scene == Scene.loading) {
        return false;
      }
      if (scene == Scene.attendance) {
        return false;
      }
      return scene == Scene.home || await context.stateManager.isHomeScene();
    });

    if (!loaded) {
      return const TaskResult.timeout('GrowStone launch did not reach home scene');
    }

    return const TaskResult.success('GrowStone home scene detected');
  }
}
