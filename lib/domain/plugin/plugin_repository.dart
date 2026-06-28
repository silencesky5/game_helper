import '../workflow/workflow.dart';
import 'plugin.dart';

/// Defines the contract for loading installed plugins.
abstract class PluginRepository {
  /// Loads the installed plugins known to the platform.
  Future<List<Plugin>> loadPlugins();

  /// Loads the workflow for [plugin].
  Future<Workflow> loadWorkflow(Plugin plugin);
}
