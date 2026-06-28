import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/automation/automation_action.dart';
import '../../domain/automation/automation_config.dart';
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
import '../../infrastructure/adb/adb_manager.dart';
import '../../infrastructure/adb/adb_device_service.dart';
import '../../infrastructure/adb/adb_screenshot_service.dart';
import '../../domain/plugin/game_profile.dart';
import '../../domain/plugin/plugin.dart';
import '../../domain/workflow/workflow.dart';
import '../../domain/workflow/workflow_runtime.dart';
import '../../infrastructure/logger/desktop_console_logger.dart';
import '../../infrastructure/storage/local_storage.dart';
import '../../domain/screenshot/screenshot_repository.dart';
import '../../domain/vision/vision_config.dart';
import '../../domain/vision/vision_repository.dart';
import '../../automation/engine/image_detector.dart';
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

  /// Plugins available for assignment in each device card.
  List<Plugin> get availablePlugins => _automationEngine.context.pluginManager.plugins;

  ScreenshotRepository get screenshotRepository => _automationEngine.context.screenshotRepository;

  ADBManager get adbManager => _automationEngine.context.deviceManager.deviceService is AdbDeviceService
      ? (_automationEngine.context.deviceManager.deviceService as AdbDeviceService).commandRunner.adbManager
      : ADBManager(logger: _automationEngine.context.loggerService);

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
      await adbManager.locateADB();
      await adbManager.validateADB();
      final devices = await context.deviceManager.detectDevices();
      context.sessionManager.clear();
      if (context.pluginManager.plugins.isEmpty) {
        await context.pluginManager.initialize();
      }
      final Plugin? plugin = context.pluginManager.getPlugin('mine_journey');
      Workflow? workflow;
      if (plugin != null) {
        workflow = await context.pluginManager.getWorkflow(plugin);
        context.loggerService.log(LogLevel.info, 'Plugin Loading complete: ${plugin.displayName} (${plugin.name})');
      }
      for (final timer in _screenshotTimers.values) {
        timer.cancel();
      }
      _screenshotTimers.clear();
      screenshotRepository.clear();
      final List<AutomationSession> sessions = <AutomationSession>[];
      for (final entry in devices.asMap().entries) {
        final device = entry.value.copyWith(name: entry.value.name.trim().isEmpty ? _defaultDeviceName(entry.key) : entry.value.name);
        final session = context.sessionManager.createSession(device).copyWith(
          plugin: plugin,
          workflow: workflow,
          taskProfile: _firstTaskProfile(plugin),
          automationConfig: await _automationConfigFor(device.id, plugin),
          character: const CharacterProfile.notLoggedIn(),
          workflowRuntime: WorkflowRuntime(context: context),
          startedAt: DateTime.now(),
          currentStep: 'Device Monitor',
        );
        context.sessionManager.updateSession(session);
        sessions.add(session);
      }
      _sessions = List<AutomationSession>.unmodifiable(sessions);
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

  Future<void> setADBPath(String path) async {
    await adbManager.setADBPath(path);
    notifyListeners();
  }

  Future<void> testADBConnection() async {
    await adbManager.validateADB();
    notifyListeners();
  }

  Future<void> rescanADB() async {
    await adbManager.rescan();
    notifyListeners();
  }

  /// Detects the current scene with template-level debug information.
  Future<void> detectSceneDebug(AutomationSession session) async {
    final report = await const ImageDetector().debugScene();
    _automationEngine.context.loggerService.log(
      LogLevel.info,
      '[Detect Scene] ${session.device.name}\n$report',
    );
    notifyListeners();
  }

  /// Asks the assigned plugin to detect the active character for one session.
  Future<void> detectCharacter(AutomationSession session) async {
    final character = await session.plugin?.implementation?.detectCharacter() ?? const CharacterProfile.notLoggedIn();
    _replaceSession(session.id, session.copyWith(character: character));
    _automationEngine.context.loggerService.log(LogLevel.info, 'Character detected: ${session.device.name} → ${character.displayName}');
  }

  Future<void> restartSession(AutomationSession session) async {
    _automationEngine.context.loggerService.log(LogLevel.info, 'Session Stop ${session.id}');
    _automationEngine.context.loggerService.log(LogLevel.info, 'Session Start ${session.id}');
    await captureScreenshot(session);
  }

  /// Updates the friendly dashboard name for a connected device session.
  void renameSessionDevice(AutomationSession session, String name) {
    final String fallbackName = _defaultDeviceName(_sessions.indexWhere((AutomationSession item) => item.id == session.id));
    final String displayName = name.trim().isEmpty ? fallbackName : name.trim();
    _replaceSession(
      session.id,
      session.copyWith(device: session.device.copyWith(name: displayName)),
    );
    _automationEngine.context.loggerService.log(LogLevel.info, 'Device Name updated: ${session.device.id} → $displayName');
  }

  /// Assigns a game plugin independently for one device session.
  Future<void> assignPlugin(AutomationSession session, String pluginId) async {
    final Plugin? plugin = _automationEngine.context.pluginManager.getPlugin(pluginId);
    Workflow? workflow;
    String currentStep = 'Plugin Unassigned';
    if (plugin != null && plugin.implementation != null) {
      workflow = await _automationEngine.context.pluginManager.getWorkflow(plugin);
      currentStep = 'Device Monitor';
    }

    final updated = AutomationSession(
      id: session.id,
      device: session.device,
      plugin: plugin,
      workflow: workflow,
      workflowRuntime: WorkflowRuntime(context: _automationEngine.context),
      state: session.state,
      logger: session.logger,
      startedAt: session.startedAt,
      currentStep: currentStep,
      taskProfile: _firstTaskProfile(plugin),
      automationConfig: await _automationConfigFor(session.device.id, plugin),
      character: const CharacterProfile.notLoggedIn(),
    );
    _replaceSession(session.id, updated);
    _automationEngine.context.sessionManager.updateSession(updated);
    _automationEngine.context.loggerService.log(LogLevel.info, 'Plugin assigned: ${session.device.name} → ${plugin?.displayName ?? '未指定'}');
  }



  /// Persists generated automation logic for one device session.
  Future<void> saveAutomationConfig(AutomationSession session, AutomationConfig config) async {
    await _automationEngine.context.storageService.write(_automationConfigKey(session.device.id), config.toJson());
    final updated = session.copyWith(automationConfig: config);
    _replaceSession(session.id, updated);
    final selectedActions = automationActionsFor(updated)
        .where((AutomationActionDefinition action) => config.isEnabled(action.id))
        .map((AutomationActionDefinition action) => action.displayName)
        .join(' → ');
    _automationEngine.context.loggerService.log(
      LogLevel.info,
      'Automation Logic saved: ${session.device.name} → ${selectedActions.isEmpty ? '全部取消' : selectedActions}',
    );
  }

  /// Returns plugin-provided automation actions for [session].
  List<AutomationActionDefinition> automationActionsFor(AutomationSession session) {
    return session.plugin?.implementation?.getAutomationActions() ?? const <AutomationActionDefinition>[];
  }

  /// Selects a task profile independently for one device session.
  void assignTaskProfile(AutomationSession session, String taskProfileId) {
    final profiles = session.plugin?.implementation?.createTaskProfiles() ?? const <TaskProfile>[];
    final TaskProfile? profile = profiles.where((TaskProfile item) => item.id == taskProfileId).firstOrNull;
    if (profile == null) return;
    final updated = session.copyWith(taskProfile: profile, workflow: profile.workflow);
    _replaceSession(session.id, updated);
    _automationEngine.context.loggerService.log(LogLevel.info, 'Task Profile selected: ${session.device.name} → ${profile.name}');
  }

  void _replaceSession(String sessionId, AutomationSession updated) {
    _sessions = _sessions
        .map((AutomationSession session) => session.id == sessionId ? updated : session)
        .toList(growable: false);
    _automationEngine.context.sessionManager.updateSession(updated);
    notifyListeners();
  }


  Future<AutomationConfig> _automationConfigFor(String deviceId, Plugin? plugin) async {
    final actions = plugin?.implementation?.getAutomationActions() ?? const <AutomationActionDefinition>[];
    final rawJson = await _automationEngine.context.storageService.read(_automationConfigKey(deviceId));
    return AutomationConfig.fromJson(deviceId, rawJson, actions);
  }

  String _automationConfigKey(String deviceId) => 'automation_config.$deviceId';

  TaskProfile? _firstTaskProfile(Plugin? plugin) {
    final profiles = plugin?.implementation?.createTaskProfiles() ?? const <TaskProfile>[];
    return profiles.isEmpty ? null : profiles.first;
  }

  String _defaultDeviceName(int index) => 'Device #${index < 0 ? 1 : index + 1}';

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
    final ADBManager adbManager = ADBManager(logger: loggerService);
    final DeviceManager deviceManager = DeviceManager(AdbDeviceService(logger: loggerService, adbManager: adbManager));
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
        screenshotService: AdbScreenshotService(logger: loggerService, adbManager: adbManager),
        screenshotRepository: screenshotRepository,
        deviceControlService: AdbDeviceControlService(logger: loggerService, adbManager: adbManager),
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
