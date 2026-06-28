import 'package:flutter/foundation.dart';

import '../../domain/automation/automation_context.dart';
import '../../domain/automation/automation_engine.dart';
import '../../domain/device/device_manager.dart';
import '../../domain/plugin/plugin_manager.dart';
import '../../domain/workflow/workflow_engine.dart';
import '../../infrastructure/adb/adb_device_service.dart';
import '../../infrastructure/logger/console_logger.dart';
import '../../infrastructure/storage/local_storage.dart';

/// Presentation controller for starting the automation pipeline.
class AutomationController extends ChangeNotifier {
  /// Creates a controller with an injectable [automationEngine].
  AutomationController({AutomationEngine? automationEngine})
      : _automationEngine = automationEngine ?? _createDefaultEngine();

  final AutomationEngine _automationEngine;
  bool _running = false;

  /// Whether an automation run has been started from the dashboard.
  bool get running => _running;

  /// Starts the Mine Journey automation pipeline.
  Future<void> start() async {
    _running = true;
    notifyListeners();

    await _automationEngine.start('mine_journey');
  }

  static AutomationEngine _createDefaultEngine() {
    final PluginManager pluginManager = PluginManager();
    final WorkflowEngine workflowEngine = WorkflowEngine();
    final DeviceManager deviceManager = DeviceManager(const AdbDeviceService());
    final ConsoleLogger loggerService = ConsoleLogger();
    final LocalStorage storageService = LocalStorage();

    return AutomationEngine(
      context: AutomationContext(
        pluginManager: pluginManager,
        workflowEngine: workflowEngine,
        deviceManager: deviceManager,
        loggerService: loggerService,
        storageService: storageService,
      ),
    );
  }
}
