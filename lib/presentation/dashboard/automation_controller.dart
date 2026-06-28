import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
import '../../domain/screenshot/device_screenshot.dart';
import '../../domain/screenshot/screenshot_repository.dart';
import '../../domain/vision/vision_config.dart';
import '../../domain/vision/vision_repository.dart';
import '../../automation/engine/image_detector.dart';
import '../../domain/vision/image_decoder.dart';
import '../../domain/vision/template_matcher.dart';
import '../../domain/vision/vision_service.dart';
import 'desktop_console_config.dart';

/// Template metadata and latest calibration state for Vision Calibration.
class VisionCalibrationTemplate {
  const VisionCalibrationTemplate({
    required this.name,
    required this.assetPath,
    required this.threshold,
    this.width,
    this.height,
    this.lastConfidence,
    this.lastMatchTime,
    this.bestScale,
    this.result,
    this.bounds,
    this.tapPosition,
  });

  final String name;
  final String assetPath;
  final double threshold;
  final int? width;
  final int? height;
  final double? lastConfidence;
  final DateTime? lastMatchTime;
  final double? bestScale;
  final String? result;
  final VisionBounds? bounds;
  final Point<int>? tapPosition;

  bool get passed => result == 'PASS';
  String get sizeLabel => width == null || height == null ? 'Unknown' : '${width}x$height';

  VisionCalibrationTemplate copyWith({
    double? threshold,
    int? width,
    int? height,
    double? lastConfidence,
    DateTime? lastMatchTime,
    double? bestScale,
    String? result,
    VisionBounds? bounds,
    Point<int>? tapPosition,
  }) {
    return VisionCalibrationTemplate(
      name: name,
      assetPath: assetPath,
      threshold: threshold ?? this.threshold,
      width: width ?? this.width,
      height: height ?? this.height,
      lastConfidence: lastConfidence ?? this.lastConfidence,
      lastMatchTime: lastMatchTime ?? this.lastMatchTime,
      bestScale: bestScale ?? this.bestScale,
      result: result ?? this.result,
      bounds: bounds ?? this.bounds,
      tapPosition: tapPosition ?? this.tapPosition,
    );
  }
}

/// GrowStone template debug data shown by the Automation Debug panel.
class GrowStoneDebugResult {
  const GrowStoneDebugResult({required this.found, this.confidence, this.rect, this.tapPosition});

  final bool found;
  final double? confidence;
  final Rectangle<int>? rect;
  final Point<int>? tapPosition;
}

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
  final Random _random = Random();
  final Map<String, GrowStoneDebugResult> _growStoneDebugResults = <String, GrowStoneDebugResult>{};
  final Map<String, Scene> _debugScenes = <String, Scene>{};
  final Set<String> _debugModeDevices = <String>{};

  final Map<String, int> _selectedCalibrationIndexes = <String, int>{};
  final Map<String, List<VisionCalibrationTemplate>> _calibrationTemplates = <String, List<VisionCalibrationTemplate>>{};

  static const List<double> calibrationThresholdOptions = <double>[0.80, 0.85, 0.90, 0.95, 0.98];
  static const List<double> calibrationScales = <double>[1.00, 0.95, 0.90, 0.85, 0.80];
  static const List<VisionCalibrationTemplate> _templateLibrary = <VisionCalibrationTemplate>[
    VisionCalibrationTemplate(name: 'GrowStone Icon', assetPath: 'assets/vision/android/growstone_icon.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Loading Logo', assetPath: 'assets/vision/loading/loading_logo.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Attendance Title', assetPath: 'assets/vision/attendance/attendance_title.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Receive All', assetPath: 'assets/vision/attendance/receive_all.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Close', assetPath: 'assets/vision/attendance/close_button.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Bag', assetPath: 'assets/vision/home/bag.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Shop', assetPath: 'assets/vision/home/shop.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Mail', assetPath: 'assets/vision/home/mail.png', threshold: 0.95),
    VisionCalibrationTemplate(name: 'Craft', assetPath: 'assets/vision/home/craft.png', threshold: 0.95),
  ];


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

  GrowStoneDebugResult? growStoneDebugFor(String deviceId) => _growStoneDebugResults[deviceId];

  Scene? debugSceneFor(String deviceId) => _debugScenes[deviceId];

  bool debugModeFor(String deviceId) => _debugModeDevices.contains(deviceId);

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
          nextStep: 'Waiting',
          currentScene: 'Unknown',
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



  List<VisionCalibrationTemplate> calibrationTemplatesFor(String deviceId) => _calibrationTemplates.putIfAbsent(deviceId, () => _templateLibrary);

  VisionCalibrationTemplate selectedCalibrationTemplateFor(String deviceId) {
    final templates = calibrationTemplatesFor(deviceId);
    final index = (_selectedCalibrationIndexes[deviceId] ?? 0).clamp(0, templates.length - 1).toInt();
    return templates[index];
  }

  void selectCalibrationTemplate(AutomationSession session, String assetPath) {
    final templates = calibrationTemplatesFor(session.device.id);
    final index = templates.indexWhere((template) => template.assetPath == assetPath);
    if (index >= 0) _selectedCalibrationIndexes[session.device.id] = index;
    notifyListeners();
  }

  void updateCalibrationThreshold(AutomationSession session, double threshold) {
    final templates = List<VisionCalibrationTemplate>.from(calibrationTemplatesFor(session.device.id));
    final index = (_selectedCalibrationIndexes[session.device.id] ?? 0).clamp(0, templates.length - 1).toInt();
    templates[index] = templates[index].copyWith(threshold: threshold);
    _calibrationTemplates[session.device.id] = List<VisionCalibrationTemplate>.unmodifiable(templates);
    notifyListeners();
  }

  Future<void> calibrateSelectedTemplate(AutomationSession session) async {
    await _captureForVision(session);
    final screenshot = screenshotRepository.latest(session.device.id);
    if (screenshot == null) return;
    final templates = List<VisionCalibrationTemplate>.from(calibrationTemplatesFor(session.device.id));
    final index = (_selectedCalibrationIndexes[session.device.id] ?? 0).clamp(0, templates.length - 1).toInt();
    final template = templates[index];
    try {
      final asset = await _loadCalibrationAsset(template);
      final image = await const ImageDecoder().decode(ImageBuffer(deviceId: session.device.id, current: screenshot, previous: screenshotRepository.previous(session.device.id)));
      TemplateMatchResult best = const TemplateMatchResult(templateName: 'N/A', found: false, confidence: 0);
      var bestScale = 1.0;
      for (final scale in calibrationScales) {
        final scaled = _scaleTemplate(asset, scale);
        final match = await const TemplateMatcher().find(image, scaled, threshold: template.threshold);
        if (match.confidence > best.confidence) {
          best = match;
          bestScale = scale;
        }
      }
      final passed = best.confidence >= template.threshold;
      final bounds = best.bounds;
      final tap = bounds == null ? null : Point<int>(bounds.x + bounds.width ~/ 2, bounds.y + bounds.height ~/ 2);
      templates[index] = template.copyWith(
        width: asset.width,
        height: asset.height,
        lastConfidence: best.confidence,
        lastMatchTime: DateTime.now(),
        bestScale: bestScale,
        result: passed ? 'PASS' : 'FAIL',
        bounds: bounds,
        tapPosition: tap,
      );
      _calibrationTemplates[session.device.id] = List<VisionCalibrationTemplate>.unmodifiable(templates);
      _automationEngine.context.loggerService.log(LogLevel.info, '[Vision Calibration] Detect ${template.name} Confidence ${best.confidence.toStringAsFixed(2)} ${passed ? 'PASS' : 'FAIL'}');
      _updateHomeSceneFromCalibration(session);
    } on FlutterError catch (error) {
      templates[index] = template.copyWith(result: 'Missing Asset', lastMatchTime: DateTime.now(), lastConfidence: 0);
      _calibrationTemplates[session.device.id] = List<VisionCalibrationTemplate>.unmodifiable(templates);
      _automationEngine.context.loggerService.log(LogLevel.error, '[Vision Calibration] ${template.name} asset unavailable: ${error.message}');
    }
    notifyListeners();
  }

  Future<void> calibrateAllTemplates(AutomationSession session) async {
    for (var i = 0; i < calibrationTemplatesFor(session.device.id).length; i++) {
      _selectedCalibrationIndexes[session.device.id] = i;
      await calibrateSelectedTemplate(session);
    }
  }

  void _updateHomeSceneFromCalibration(AutomationSession session) {
    final byName = {for (final template in calibrationTemplatesFor(session.device.id)) template.name: template};
    final homePassed = <String>['Bag', 'Shop', 'Mail', 'Craft'].every((name) => byName[name]?.passed ?? false);
    if (homePassed) _replaceSession(session.id, session.copyWith(currentScene: 'Home'));
  }

  Future<TemplateAsset> _loadCalibrationAsset(VisionCalibrationTemplate template) async {
    final bytes = (await rootBundle.load(template.assetPath)).buffer.asUint8List();
    final image = await const ImageDecoder().decode(ImageBuffer(deviceId: 'template', current: DeviceScreenshot(deviceId: 'template', pngBytes: bytes, updatedAt: DateTime.now()), previous: null));
    return TemplateAsset(name: template.name, width: image.width, height: image.height, rgbaBytes: image.rgbaBytes);
  }

  TemplateAsset _scaleTemplate(TemplateAsset template, double scale) {
    if (scale == 1) return template;
    final width = max(1, (template.width * scale).round());
    final height = max(1, (template.height * scale).round());
    final bytes = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final sourceX = min(template.width - 1, (x / scale).floor());
        final sourceY = min(template.height - 1, (y / scale).floor());
        final sourceOffset = ((sourceY * template.width) + sourceX) * 4;
        final targetOffset = ((y * width) + x) * 4;
        bytes[targetOffset] = template.rgbaBytes[sourceOffset];
        bytes[targetOffset + 1] = template.rgbaBytes[sourceOffset + 1];
        bytes[targetOffset + 2] = template.rgbaBytes[sourceOffset + 2];
        bytes[targetOffset + 3] = template.rgbaBytes[sourceOffset + 3];
      }
    }
    return TemplateAsset(name: template.name, width: width, height: height, rgbaBytes: bytes);
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
    final result = await _automationEngine.context.screenshotService.capturePreview(session.device);
    switch (result) {
      case Success(:final value):
        _automationEngine.context.screenshotRepository.save(value);
        final path = await _saveDebugScreenshot(value);
        _automationEngine.context.loggerService.log(LogLevel.info, 'ADB Screenshot Success: ${session.device.name} (${session.device.id}) ${value.sizeLabel}');
        _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Screenshot saved: $path');
      case Failure(:final error):
        _automationEngine.context.loggerService.log(LogLevel.error, 'Capture Failed: ${session.device.name} (${session.device.id}) ${error.message}');
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


  Future<bool> _captureForVision(AutomationSession session) async {
    final result = await _automationEngine.context.screenshotService.captureForVision(session.device);
    switch (result) {
      case Success(:final value):
        _automationEngine.context.screenshotRepository.save(value);
        _automationEngine.context.loggerService.log(LogLevel.info, '[ADB Screenshot] Success ${value.sizeLabel}');
        notifyListeners();
        return true;
      case Failure(:final error):
        _automationEngine.context.loggerService.log(LogLevel.error, '[ADB Screenshot] Capture Failed: ${error.message}');
        notifyListeners();
        return false;
    }
  }

  /// Detects the current scene with template-level debug information.
  Future<void> detectSceneDebug(AutomationSession session) async {
    await _captureForVision(session);
    final report = await const ImageDetector().debugScene();
    _automationEngine.context.loggerService.log(
      LogLevel.info,
      '[Detect Scene] ${session.device.name}\n$report',
    );
    notifyListeners();
  }


  /// Toggles verbose debug logging for a device session.
  void toggleDebugMode(AutomationSession session, bool enabled) {
    if (enabled) {
      _debugModeDevices.add(session.device.id);
    } else {
      _debugModeDevices.remove(session.device.id);
    }
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Debug Mode ${enabled ? 'ON' : 'OFF'}: ${session.device.name}');
    notifyListeners();
  }

  /// Detects and displays the current scene for one device.
  Future<void> detectScene(AutomationSession session) async {
    await _captureForVision(session);
    final scene = await const ImageDetector().detectScene();
    _debugScenes[session.device.id] = scene;
    _replaceSession(session.id, session.copyWith(currentScene: _sceneLabel(scene)));
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Detect Scene ${session.device.name}: ${_sceneLabel(scene)}');
  }

  /// Detects the GrowStone icon and records rectangle/tap preview details.
  Future<GrowStoneDebugResult> detectGrowStone(AutomationSession session) async {
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Detect GrowStone');
    await _captureForVision(session);
    final detector = const ImageDetector();
    final rect = await detector.findTemplateRect(VisionTemplates.androidGrowstoneIcon);
    final found = rect != null || await detector.findIcon(VisionTemplates.androidGrowstoneIcon);
    final tapPosition = rect == null ? null : _randomPointIn(rect);
    final result = GrowStoneDebugResult(found: found, confidence: found ? 1 : 0, rect: rect, tapPosition: tapPosition);
    _growStoneDebugResults[session.device.id] = result;
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Found ${found ? 'YES' : 'NO'}');
    if (rect != null) {
      _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Confidence ${result.confidence!.toStringAsFixed(2)}');
      _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Rect L${rect.left} T${rect.top} R${rect.right} B${rect.bottom}');
      _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Random Position X=${tapPosition!.x} Y=${tapPosition.y}');
    } else if (!found) {
      _automationEngine.context.loggerService.log(LogLevel.warning, '[Automation Debug] GrowStone Icon Not Found');
    }
    notifyListeners();
    return result;
  }

  /// Calculates a new random tap preview without sending ADB input.
  Future<void> previewRandomTap(AutomationSession session) async {
    final current = _growStoneDebugResults[session.device.id];
    final result = current?.rect == null ? await detectGrowStone(session) : GrowStoneDebugResult(found: current!.found, confidence: current.confidence, rect: current.rect, tapPosition: _randomPointIn(current.rect!));
    _growStoneDebugResults[session.device.id] = result;
    if (result.tapPosition != null) {
      _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Generate Random X=${result.tapPosition!.x} Y=${result.tapPosition!.y}');
    }
    notifyListeners();
  }


  /// Records that the dashboard overlay is visible for the latest GrowStone rectangle.
  void logVisionOverlay(AutomationSession session) {
    final result = _growStoneDebugResults[session.device.id];
    if (result?.rect == null) {
      _automationEngine.context.loggerService.log(LogLevel.warning, '[Automation Debug] Vision Overlay unavailable: detect GrowStone first');
    } else {
      final rect = result!.rect!;
      _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Vision Overlay Rect L${rect.left} T${rect.top} R${rect.right} B${rect.bottom} Tap=${result.tapPosition}');
    }
    notifyListeners();
  }

  /// Runs the popup debug hook without continuing automation.
  void testPopup(AutomationSession session) {
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Test Popup requested for ${session.device.name}');
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Stop');
    notifyListeners();
  }

  /// Detects GrowStone, random-taps the icon once through ADB, and stops.
  Future<void> testGrowStoneTap(AutomationSession session) async {
    final result = await detectGrowStone(session);
    if (!result.found || result.tapPosition == null) {
      _automationEngine.context.loggerService.log(LogLevel.warning, '[Automation Debug] Test Tap stopped: GrowStone Icon Not Found');
      return;
    }
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] ADB Tap X=${result.tapPosition!.x} Y=${result.tapPosition!.y}');
    await _executeAction(session, TapAction(result.tapPosition!.x, result.tapPosition!.y));
    _automationEngine.context.loggerService.log(LogLevel.info, '[Automation Debug] Stop');
    notifyListeners();
  }

  Point<int> _randomPointIn(Rectangle<int> rect) {
    final width = max(1, rect.width);
    final height = max(1, rect.height);
    return Point<int>(rect.left + _random.nextInt(width), rect.top + _random.nextInt(height));
  }

  String _sceneLabel(Scene scene) => switch (scene) {
        Scene.android => 'Android',
        Scene.loading => 'Loading',
        Scene.attendance => 'Attendance',
        Scene.home => 'Home',
        Scene.bag => 'Bag',
        Scene.mail => 'Mail',
        Scene.shop => 'Shop',
        Scene.unknown => 'Unknown',
      };

  Future<String> _saveDebugScreenshot(DeviceScreenshot screenshot) async {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final date = '${now.year}-${two(now.month)}-${two(now.day)}';
    final time = '${two(now.hour)}-${two(now.minute)}-${two(now.second)}';
    final directory = Directory('logs/screenshots/$date');
    await directory.create(recursive: true);
    final file = File('${directory.path}/$time.png');
    await file.writeAsBytes(screenshot.pngBytes, flush: true);
    return file.path;
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
    String nextStep = 'Waiting';
    String currentScene = session.currentScene;
    if (plugin != null && plugin.implementation != null) {
      workflow = await _automationEngine.context.pluginManager.getWorkflow(plugin);
      currentStep = 'Device Monitor';
      nextStep = 'Waiting';
      currentScene = 'Unknown';
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
      nextStep: nextStep,
      currentScene: currentScene,
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
