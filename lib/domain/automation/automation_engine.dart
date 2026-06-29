import '../../automation/engine/action_controller.dart' as launch_runtime;
import '../../automation/engine/image_detector.dart' as launch_runtime;
import '../../automation/engine/state_manager.dart' as launch_runtime;
import '../../automation/models/task_context.dart' as launch_runtime;
import '../../automation/models/task_result.dart' as launch_result;
import '../../automation/tasks/launch/launch_task.dart';
import '../../emulator/emulator.dart';
import '../device/device.dart';
import '../logger/logger.dart';
import '../core/result.dart';
import 'automation_context.dart';
import 'automation_session.dart';
import 'automation_state.dart';

/// Platform automation orchestrator.
///
/// The engine is the only orchestrator connecting device discovery, sessions,
/// plugin loading, workflow execution, and engine logging.
class AutomationEngine {
  /// Creates an automation engine from explicit domain dependencies.
  const AutomationEngine({required this.context});

  /// Domain services available to the automation runtime.
  final AutomationContext context;

  /// Creates a new idle automation session for [device].
  AutomationSession createSession(Device device) {
    return context.sessionManager.createSession(device);
  }

  /// Runs the SPEC-008 version-1 launch-only automation pipeline.
  ///
  /// This intentionally bypasses queues, schedulers, workflows, and plugins:
  /// `AutomationEngine.start()` creates/uses sessions, runs [LaunchTask], and
  /// stops as soon as GrowStone Home is detected.
  Future<List<AutomationSession>> start(String pluginId) async {
    context.loggerService.log(LogLevel.info, 'Automation Start');
    final List<Device> devices = await context.deviceManager.detectDevices();

    final List<Device> activeDevices = devices.isEmpty ? _fallbackDemoDevices() : devices;
    final List<AutomationSession> sessions = <AutomationSession>[];

    for (final Device device in activeDevices.where((Device device) => device.isOnline)) {
      final AutomationSession existingSession = context.sessionManager.sessions.where((AutomationSession item) => item.device.id == device.id).firstOrNull ?? createSession(device);
      var session = startSession(
        existingSession.copyWith(
          startedAt: DateTime.now(),
          currentStep: 'Launch Game',
          nextStep: 'Detect Scene',
          currentScene: 'Unknown',
        ),
      );
      context.sessionManager.updateSession(session);

      void updateRuntime({String? task, String? nextStep, String? scene}) {
        session = session.copyWith(
          currentStep: task,
          nextStep: nextStep,
          currentScene: scene,
        );
        context.sessionManager.updateSession(session);
      }

      final taskContext = launch_runtime.TaskContext(
        emulator: Emulator(id: device.id, name: device.name, adbPort: 0),
        stateManager: launch_runtime.StateManager(
          imageDetector: launch_runtime.ImageDetector(
            screenshotRepository: context.screenshotRepository,
            deviceId: device.id,
            logger: context.loggerService,
            loadAssetBytes: context.visionService.loadAssetBytes,
            refreshScreenshot: () async {
              final result = await context.screenshotService.captureForVision(device);
              switch (result) {
                case Success(:final value):
                  context.screenshotRepository.save(value);
                  context.loggerService.log(LogLevel.info, '[ADB Screenshot] Success ${value.sizeLabel}');
                case Failure(:final error):
                  context.loggerService.log(LogLevel.warning, '[ADB Screenshot] Capture Failed: ${error.message}');
              }
            },
          ),
        ),
        actionController: launch_runtime.ActionController(
          logger: context.loggerService,
        ),
        log: (String message) {
          context.loggerService.log(LogLevel.info, message);
          final lower = message.toLowerCase();
          if (lower.contains('android')) updateRuntime(scene: 'Android', nextStep: 'Launch GrowStone');
          if (lower.contains('launch')) updateRuntime(task: 'Launch Game', nextStep: 'Waiting Home');
          if (lower.contains('loading')) updateRuntime(scene: 'Loading', nextStep: 'Waiting Loading');
          if (lower.contains('attendance')) updateRuntime(scene: 'Attendance', nextStep: 'Handle Popup');
          if (lower.contains('home')) updateRuntime(scene: 'Home', nextStep: 'Finish');
        },
      );

      final result = await const LaunchTask().execute(taskContext);
      if (result.status == launch_result.TaskResultStatus.success) {
        updateRuntime(task: 'Launch Complete', nextStep: 'Stop', scene: 'Home');
        session = session.copyWith(state: AutomationState.completed);
        context.sessionManager.updateSession(session);
        context.loggerService.log(LogLevel.info, 'Launch Success');
      } else {
        session = session.copyWith(
          state: AutomationState.failed,
          currentStep: 'Launch Failed',
          nextStep: 'Stop',
        );
        context.sessionManager.updateSession(session);
        context.loggerService.log(LogLevel.error, 'Launch Failed: ${result.message}');
      }
      sessions.add(session);
    }

    return context.sessionManager.sessions;
  }

  /// Marks [session] as running without executing workflow steps.
  AutomationSession startSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.running);
  }

  /// Marks [session] as paused without operating devices or workflow steps.
  AutomationSession pauseSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.paused);
  }

  /// Marks [session] as running without executing workflow steps.
  AutomationSession resumeSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.running);
  }

  /// Marks [session] as stopped without operating devices or workflow steps.
  AutomationSession stopSession(AutomationSession session) {
    return session.copyWith(state: AutomationState.stopped);
  }

  List<Device> _fallbackDemoDevices() {
    return const <Device>[
      Device(id: 'demo-ldplayer-1', name: 'LDPlayer1', status: DeviceStatus.online),
      Device(id: 'demo-ldplayer-2', name: 'LDPlayer2', status: DeviceStatus.online),
      Device(id: 'demo-ldplayer-3', name: 'LDPlayer3', status: DeviceStatus.offline),
      Device(id: 'demo-ldplayer-4', name: 'LDPlayer4', status: DeviceStatus.online),
    ];
  }
}
