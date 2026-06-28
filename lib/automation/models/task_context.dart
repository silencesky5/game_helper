import '../../emulator/emulator.dart';
import '../engine/action_controller.dart';
import '../engine/state_manager.dart';

/// Dependencies provided to an individual task plugin during execution.
class TaskContext {
  /// Creates a task context.
  const TaskContext({required this.emulator, required this.stateManager, required this.actionController, required this.log});

  /// Emulator that owns this task run.
  final Emulator emulator;

  /// Screen/game state gateway. Tasks must read state through this object.
  final StateManager stateManager;

  /// Centralized action gateway. Tasks must not call ADB directly.
  final ActionController actionController;

  /// Task-scoped logger callback.
  final void Function(String message) log;
}
