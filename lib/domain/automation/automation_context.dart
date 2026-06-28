import '../control/device_control_service.dart';
import '../device/device_manager.dart';
import '../logger/logger_service.dart';
import '../plugin/plugin_manager.dart';
import '../screenshot/screenshot_repository.dart';
import '../screenshot/screenshot_service.dart';
import '../storage/storage_service.dart';
import '../vision/vision_repository.dart';
import '../vision/vision_service.dart';
import '../workflow/workflow_engine.dart';
import 'session_manager.dart';

/// Immutable dependency bundle for automation runtime services.
class AutomationContext {
  /// Plugin manager available to automation sessions.
  final PluginManager pluginManager;

  /// Workflow engine available to automation sessions.
  final WorkflowEngine workflowEngine;

  /// Device manager available to automation sessions.
  final DeviceManager deviceManager;

  /// Logger service available to automation sessions.
  final LoggerService loggerService;

  /// Session manager that maps one device to one session.
  final SessionManager sessionManager;

  /// Storage service available to automation sessions.
  final StorageService storageService;

  /// Captures Android screenshots.
  final ScreenshotService screenshotService;

  /// Stores latest screenshots for desktop preview.
  final ScreenshotRepository screenshotRepository;

  /// Sends control commands to Android devices.
  final DeviceControlService deviceControlService;

  /// Shared screenshot analysis service.
  final VisionService visionService;

  /// Stores latest vision analysis for the desktop console and workflows.
  final VisionRepository visionRepository;

  /// Creates an immutable automation context from explicit dependencies.
  const AutomationContext({
    required this.pluginManager,
    required this.workflowEngine,
    required this.deviceManager,
    required this.loggerService,
    required this.sessionManager,
    required this.storageService,
    required this.screenshotService,
    required this.screenshotRepository,
    required this.deviceControlService,
    required this.visionService,
    required this.visionRepository,
  });
}
