import '../../emulator/emulator.dart';
import '../../services/database/local_database.dart';
import '../models/task_context.dart';
import '../models/task_result.dart';
import '../tasks/default_tasks.dart';
import 'action_controller.dart';
import 'game_task.dart';
import 'state_manager.dart';
import 'task_executor.dart';
import 'task_scheduler.dart';

/// Plugin-based automation engine with a single [start] entry point.
class AutomationEngine {
  /// Creates the platform automation engine.
  AutomationEngine({
    required this.database,
    List<GameTask>? tasks,
    this.scheduler = const TaskScheduler(),
    this.executor = const TaskExecutor(),
    StateManager? stateManager,
    ActionController? actionController,
    this.log = _defaultLog,
  })  : tasks = tasks ?? defaultGameTasks,
        stateManager = stateManager ?? StateManager(),
        actionController = actionController ?? ActionController();

  final LocalDatabase database;
  final List<GameTask> tasks;
  final TaskScheduler scheduler;
  final TaskExecutor executor;
  final StateManager stateManager;
  final ActionController actionController;
  final void Function(String message) log;

  /// Loads the emulator profile, creates a priority queue, and executes tasks.
  Future<List<TaskResult>> start(Emulator emulator) async {
    final profile = await database.loadProfile(emulator.id);
    final queue = scheduler.createQueue(profile, tasks);
    final context = TaskContext(
      emulator: emulator,
      stateManager: stateManager,
      actionController: actionController,
      log: _timestampedLog,
    );
    return executor.execute(queue, context);
  }

  void _timestampedLog(String message) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    log('$hh:$mm:$ss $message');
  }

  static void _defaultLog(String message) {}
}
