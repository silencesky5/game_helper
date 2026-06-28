import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/automation/automation_context.dart';
import '../../domain/automation/automation_engine.dart';
import '../../domain/automation/automation_session.dart';
import '../../domain/automation/session_manager.dart';
import '../../domain/device/device_manager.dart';
import '../../domain/plugin/plugin_manager.dart';
import '../../domain/workflow/workflow_engine.dart';
import '../../domain/action/device_action.dart';
import '../../domain/command/command_queue.dart';
import '../../domain/core/result.dart';
import '../../domain/logger/logger.dart';
import '../../infrastructure/adb/adb_device_control_service.dart';
import '../../infrastructure/adb/adb_device_service.dart';
import '../../infrastructure/adb/adb_screenshot_service.dart';
import '../../infrastructure/logger/console_logger.dart';
import '../../infrastructure/storage/local_storage.dart';
import '../../domain/screenshot/screenshot_repository.dart';
import '../../domain/vision/vision_config.dart';
import '../../domain/vision/vision_repository.dart';
import '../../domain/vision/vision_service.dart';

/// Presentation controller for starting the automation pipeline.
class AutomationController extends ChangeNotifier {
  /// Creates a controller with an injectable [automationEngine].
  AutomationController({AutomationEngine? automationEngine})
      : _automationEngine = automationEngine ?? _createDefaultEngine();

  final AutomationEngine _automationEngine;
  bool _running = false;
  List<AutomationSession> _sessions = const <AutomationSession>[];
  final Map<String, Timer> _screenshotTimers = <String, Timer>{};

  /// Whether an automation run has been started from the dashboard.
  bool get running => _running;

  /// Sessions shown by the desktop console.
  List<AutomationSession> get sessions => _sessions;

  ScreenshotRepository get screenshotRepository => _automationEngine.context.screenshotRepository;

  VisionRepository get visionRepository => _automationEngine.context.visionRepository;

  /// Starts the Mine Journey automation pipeline.
  Future<void> start() async {
    _running = true;
    notifyListeners();

    _sessions = await _automationEngine.start('mine_journey');
    _startScreenshotLoops();
    _running = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final Timer timer in _screenshotTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> captureScreenshot(AutomationSession session) async {
    final result = await _automationEngine.context.screenshotService.capture(session.device);
    switch (result) {
      case Success(:final value):
        _automationEngine.context.screenshotRepository.save(value);
        await _automationEngine.context.visionService.analyze(session.device.id);
      case Failure(:final error):
        _automationEngine.context.loggerService.log(LogLevel.error, '[ADB] Capture Screenshot failed: ${error.message}');
    }
    notifyListeners();
  }

  Future<void> tapTest(AutomationSession session) => _executeAction(session, const TapAction(200, 200));

  Future<void> swipeTest(AutomationSession session) => _executeAction(session, const SwipeAction(200, 800, 200, 300));

  Future<void> restartSession(AutomationSession session) async {
    _automationEngine.context.loggerService.log(LogLevel.info, 'Session Stop ${session.id}');
    _automationEngine.context.loggerService.log(LogLevel.info, 'Session Start ${session.id}');
    await captureScreenshot(session);
  }

  void _startScreenshotLoops() {
    for (final Timer timer in _screenshotTimers.values) {
      timer.cancel();
    }
    _screenshotTimers.clear();
    for (final AutomationSession session in _sessions) {
      if (!session.device.isOnline) continue;
      _screenshotTimers[session.device.id] = Timer.periodic(
        const Duration(seconds: 1),
        (_) => captureScreenshot(session),
      );
    }
  }

  Future<void> _executeAction(AutomationSession session, DeviceAction action) async {
    final queue = CommandQueue()..enqueue(action);
    final Result<void> result = await queue.execute(
      ActionContext(
        session: session,
        deviceControlService: _automationEngine.context.deviceControlService,
        logger: _automationEngine.context.loggerService,
      ),
    );
    if (result.isFailure) {
      result as Failure<void>;
      _automationEngine.context.loggerService.log(LogLevel.error, '[ADB] ${action.label} failed: ${result.error.message}');
    }
  }

  static AutomationEngine _createDefaultEngine() {
    final PluginManager pluginManager = PluginManager();
    final WorkflowEngine workflowEngine = WorkflowEngine();
    final DeviceManager deviceManager = DeviceManager(const AdbDeviceService());
    final ConsoleLogger loggerService = ConsoleLogger();
    final LocalStorage storageService = LocalStorage();
    final SessionManager sessionManager = SessionManager();
    final ScreenshotRepository screenshotRepository = ScreenshotRepository();
    final VisionRepository visionRepository = VisionRepository();

    return AutomationEngine(
      context: AutomationContext(
        pluginManager: pluginManager,
        workflowEngine: workflowEngine,
        deviceManager: deviceManager,
        loggerService: loggerService,
        sessionManager: sessionManager,
        storageService: storageService,
        screenshotService: AdbScreenshotService(logger: loggerService),
        screenshotRepository: screenshotRepository,
        deviceControlService: AdbDeviceControlService(logger: loggerService),
        visionService: VisionService(
          screenshotRepository: screenshotRepository,
          visionRepository: visionRepository,
          config: const VisionConfig(),
          logger: loggerService,
        ),
        visionRepository: visionRepository,
      ),
    );
  }
}
