import '../workflow/steps/delay_step.dart';
import '../workflow/steps/log_step.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_step.dart';
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
    for (final Plugin plugin in _plugins) {
      await plugin.implementation?.onLoad();
    }
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
  Future<Workflow> getWorkflow(Plugin plugin) async {
    return plugin.implementation?.createWorkflow() ?? _repository.loadWorkflow(plugin);
  }
}

/// Empty Mine Journey starter plugin used to validate the plugin boundary.
class MineJourneyPlugin implements GamePlugin {
  /// Creates the Mine Journey starter plugin.
  const MineJourneyPlugin();

  @override
  String get id => 'mine_journey';

  @override
  String get name => 'Mine Journey';

  @override
  Future<void> onLoad() async {}

  @override
  Future<void> onUnload() async {}

  @override
  Workflow createWorkflow() {
    return const Workflow(
      id: 'mine_journey_dummy_workflow',
      name: 'Mine Journey Dummy Workflow',
      description: 'Dummy Sprint 1 workflow with only log and delay steps.',
      version: '1.0',
      steps: <WorkflowStep>[
        LogStep(id: 'log_start', message: 'Dummy workflow started'),
        DelayStep(id: 'delay_demo', milliseconds: 250),
        LogStep(id: 'log_finish', message: 'Dummy workflow finished'),
      ],
    );
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
        description: 'Empty starter plugin for the first execution pipeline.',
        icon: 'extension',
        enabled: true,
        implementation: MineJourneyPlugin(),
      ),
    ];
  }

  @override
  Future<Workflow> loadWorkflow(Plugin plugin) async {
    return const Workflow(
      id: 'mine_journey_dummy_workflow',
      name: 'Mine Journey Dummy Workflow',
      description: 'Dummy Sprint 1 workflow with only log and delay steps.',
      version: '1.0',
      steps: <WorkflowStep>[
        LogStep(id: 'log_start', message: 'Dummy workflow started'),
        DelayStep(id: 'delay_demo', milliseconds: 250),
        LogStep(id: 'log_finish', message: 'Dummy workflow finished'),
      ],
    );
  }
}
