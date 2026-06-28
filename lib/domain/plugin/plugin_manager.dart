import '../workflow/steps/tap_step.dart';
import '../workflow/workflow.dart';
import 'plugin.dart';
import 'plugin_repository.dart';

/// Coordinates plugin loading for application features.
class PluginManager {
  final PluginRepository _repository;
  List<Plugin> _plugins = const <Plugin>[];

  /// Creates a plugin manager with a replaceable [repository].
  PluginManager({PluginRepository? repository})
      : _repository = repository ?? const MockPluginRepository();

  /// Loads plugin metadata into memory.
  Future<void> initialize() async {
    _plugins = List<Plugin>.unmodifiable(await _repository.loadPlugins());
  }

  /// Installed plugins loaded by [initialize].
  List<Plugin> get plugins => _plugins;

  /// Returns the loaded plugin with [id], or null when it does not exist.
  Plugin? getPlugin(String id) {
    for (final Plugin plugin in _plugins) {
      if (plugin.id == id) {
        return plugin;
      }
    }

    return null;
  }

  /// Loads the workflow for [plugin].
  Future<Workflow> getWorkflow(Plugin plugin) {
    return _repository.loadWorkflow(plugin);
  }
}

/// Mock plugin repository used until filesystem discovery is implemented.
class MockPluginRepository implements PluginRepository {
  /// Creates a mock plugin repository.
  const MockPluginRepository();

  @override
  Future<List<Plugin>> loadPlugins() async {
    return const <Plugin>[
      Plugin(
        id: 'mine_journey',
        name: 'Mine Journey',
        version: '1.0',
        author: 'Game Helper Team',
        description: 'Starter plugin metadata for the first execution pipeline.',
        icon: 'extension',
        enabled: true,
      ),
    ];
  }

  @override
  Future<Workflow> loadWorkflow(Plugin plugin) async {
    return const Workflow(
      id: 'mine_journey_mock_workflow',
      name: 'Mine Journey Mock Workflow',
      description: 'Mock workflow that sends one tap through the execution pipeline.',
      version: '1.0',
      steps: <TapStep>[
        TapStep(id: 'tap_300_500', x: 300, y: 500),
      ],
    );
  }
}
