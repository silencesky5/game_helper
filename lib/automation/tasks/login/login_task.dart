import '../../engine/image_detector.dart';
import '../../models/task_context.dart';
import '../../models/task_result.dart';
import '../../engine/game_task.dart';
import '../../navigation/navigation_service.dart';

/// Launches GrowStone from Android desktop and waits until gameplay can resume.
class LoginTask extends GameTask {
  /// Creates the GrowStone launch task.
  const LoginTask({this.navigator = const NavigationService()})
      : super(id: 'launch_growstone', name: 'Launch GrowStone', priority: 100);

  /// Scene-first navigation service used by this task.
  final NavigationService navigator;

  static const String growStonePackageName = 'com.superbox.aos.growstone';

  @override
  Future<TaskResult> execute(TaskContext context) async {
    final initialScene = await context.stateManager.detectScene();
    if (initialScene == Scene.home || await context.stateManager.isHomeScene()) {
      return const TaskResult.success('GrowStone home scene already detected');
    }

    if (initialScene != Scene.android) {
      return const TaskResult.retry('GrowStone is not on Android desktop');
    }

    context.log('Android desktop detected; launching GrowStone through Navigator');
    if (!await navigator.launchGame(context)) {
      return const TaskResult.retry(
        'GrowStone launch did not enter a known game scene',
      );
    }
    if (!await navigator.waitLoading(context)) {
      return const TaskResult.timeout('GrowStone loading scene timed out');
    }
    if (!await navigator.waitHome(context)) {
      return const TaskResult.timeout('GrowStone launch did not reach home scene');
    }

    return const TaskResult.success('GrowStone home scene detected');
  }
}
