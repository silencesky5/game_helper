import '../device/device_manager.dart';
import '../logger/logger_service.dart';
import '../plugin/plugin_manager.dart';
import '../storage/storage_service.dart';
import '../workflow/workflow_engine.dart';

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

  /// Storage service available to automation sessions.
  final StorageService storageService;

  /// Creates an immutable automation context from explicit dependencies.
  const AutomationContext({
    required this.pluginManager,
    required this.workflowEngine,
    required this.deviceManager,
    required this.loggerService,
    required this.storageService,
  });
}
