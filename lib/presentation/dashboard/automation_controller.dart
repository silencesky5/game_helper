import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/automation/automation_context.dart';
import '../../domain/automation/automation_engine.dart';
import '../../domain/automation/automation_session.dart';
import '../../domain/automation/session_manager.dart';
import '../../domain/decision/decision_config.dart';
import '../../domain/decision/decision_state.dart';
import '../../domain/device/device_manager.dart';
import '../../domain/perception/perception_config.dart';
import '../../domain/perception/perception_repository.dart';
import '../../domain/perception/perception_service.dart';
import '../../domain/plugin/plugin_manager.dart';
import '../../domain/workflow/workflow_engine.dart';
import '../../domain/action/device_action.dart';
import '../../domain/command/command_queue.dart';
import '../../domain/core/result.dart';
import '../../domain/logger/logger.dart';
import '../../infrastructure/adb/adb_device_control_service.dart';
import '../../infrastructure/adb/adb_device_service.dart';
import '../../infrastructure/adb/adb_screenshot_service.dart';
import '../../domain/plugin/plugin.dart';
import '../../domain/workflow/workflow.dart';
import '../../domain/workflow/workflow_runtime.dart';
import '../../infrastructure/logger/desktop_console_logger.dart';
import '../../infrastructure/storage/local_storage.dart';
import '../../domain/screenshot/screenshot_repository.dart';
import '../../domain/vision/vision_config.dart';
import '../../domain/vision/vision_repository.dart';
import '../../domain/vision/vision_service.dart';
import 'desktop_console_config.dart';

/// Presentation controller for starting the automation pipeline.
class AutomationController extends ChangeNotifier {
  /// Creates a controller with an injectable [automationEngine].
  AutomationController({AutomationEngine? automationEngine})
      : _automationEngine = automationEngine ?? _createDefaultEngine();

  final AutomationEngine _automationEngine;
  bool _running = false;
  bool _detecting = false;
  List<AutomationSession> _sessions = const <AutomationSession>[];
  final Map<String, Timer> _screenshotTimers = <String, Timer>{};
  final DesktopConsoleConfig _desktopConfig = DesktopConsoleConfig.loadSync();

  /// Whether an automation run has been started from the dashboard.
  bool get running => _running;

  /// Whether the console is detecting ADB devices.
  bool get detecting => _detecting;

  /// Sessions shown by the desktop console.
  List<AutomationSession> get sessions => _sessions;

  ScreenshotRepository get screenshotRepository => _automationEngine.context.screenshotRepository;

  VisionRepository get visionRepository => _automationEngine.context.visionRepository;

  PerceptionRepository get perceptionRepository => _automationEngine.context.perceptionRepository;

  DecisionRepository get decisionRepository => _automationEngine.context.decisionRepository;

  List<String> get logs {
    final logger = _automationEngine.context.loggerService;
    return logger is DesktopConsoleLogger ? logger.entries : const <String>[];
  }

  /// Detects connected ADB devices and creates desktop sessions without running workflows.
  Future<void> initializeDesktopConsole() async {
    _detecting = true;
    notifyListeners();
    try {
      final context = _automationEngine.context;
      context.loggerService.log(LogLevel.info, 'Desktop Console → Automation Engine → ADB Device Detection');
      final devices = await context.deviceManager.detectDevices();
      context.sessionManager.clear();
      if (context.pluginManager.plugins.isEmpty) {
        await context.pluginManager.initialize();
      }
      final Plugin? plugin = context.pluginManager.getPlugin('mine_journey');
      Workflow? workflow;
      if (plugin != null) {
        workflow = await context.pluginManager.getWorkflow(plugin);
        context.loggerService.log(LogLevel.info, 'Plugin Loading complete: ${plugin.name}');
      }
      for (final timer in _screenshotTimers.values) {
        timer.cancel();
      }
      _screenshotTimers.clear();
      screenshotRepository.clear();
      _sessions = devices.map((device) {
        final session = context.sessionManager.createSession(device).copyWith(
          plugin: plugin,
          workflow: workflow,
          workflowRuntime: WorkflowRuntime(context: context),
          startedAt: DateTime.now(),
          currentStep: 'Device Monitor',
        );
        context.sessionManager.updateSession(session);
        return session;
      }).toList(growable: false);
      context.loggerService.log(LogLevel.info, 'Session Creation complete: ${_sessions.length} ADB device(s) detected');
      _startScreenshotLoops(captureImmediately: true);
    } finally {
      _detecting = false;
      notifyListeners();
    }
  }

  /// Starts the Mine Journey automation pipeline.
  Future<void> start() async {
    if (_sessions.isEmpty) {
      await initializeDesktopConsole();
    }
    if (_sessions.isEmpty) {
      _automationEngine.context.loggerService.log(
        LogLevel.warning,
        'Automation start blocked: no connected ADB devices detected.',
      );
      return;
    }
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
        _automationEngine.context.loggerService.log(LogLevel.info, 'Screenshot Updated: ${session.device.name} (${session.device.id})');
      case Failure(:final error):
        _automationEngine.context.loggerService.log(LogLevel.error, 'Screenshot Failed: ${session.device.name} (${session.device.id}) ${error.message}');
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

  void _startScreenshotLoops({bool captureImmediately = false}) {
    for (final Timer timer in _screenshotTimers.values) {
      timer.cancel();
    }
    _screenshotTimers.clear();
    for (final AutomationSession session in _sessions) {
      if (!session.device.isOnline) continue;
      _screenshotTimers[session.device.id] = Timer.periodic(
        _desktopConfig.screenshotRefreshInterval,
        (_) => captureScreenshot(session),
      );
      if (captureImmediately) {
        unawaited(captureScreenshot(session));
      }
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
    final DesktopConsoleLogger loggerService = DesktopConsoleLogger();
    final DeviceManager deviceManager = DeviceManager(AdbDeviceService(logger: loggerService));
    final LocalStorage storageService = LocalStorage();
    final SessionManager sessionManager = SessionManager();
    final ScreenshotRepository screenshotRepository = ScreenshotRepository();
    final VisionRepository visionRepository = VisionRepository();
    final PerceptionRepository perceptionRepository = PerceptionRepository();
    final VisionService visionService = VisionService(
      screenshotRepository: screenshotRepository,
      visionRepository: visionRepository,
      config: const VisionConfig(),
      logger: loggerService,
    );

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
        visionService: visionService,
        perceptionService: PerceptionService(
          visionService: visionService,
          visionRepository: visionRepository,
          screenshotRepository: screenshotRepository,
          perceptionRepository: perceptionRepository,
          config: const PerceptionConfig(),
          logger: loggerService,
        ),
        visionRepository: visionRepository,
        perceptionRepository: perceptionRepository,
        decisionConfig: DecisionConfig.loadSync(),
        decisionRepository: DecisionRepository(),
      ),
    );
  }
}
