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
        description: 'Starter plugin metadata for the plugin manager foundation.',
        icon: 'extension',
        enabled: true,
      ),
    ];
  }
}
