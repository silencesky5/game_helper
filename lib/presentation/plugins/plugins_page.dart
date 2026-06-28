import 'package:flutter/material.dart';

import '../../domain/plugin/plugin.dart';
import '../../domain/plugin/plugin_manager.dart';

/// Read-only page that lists installed plugins.
class PluginsPage extends StatefulWidget {
  /// Creates a plugin list page backed by [pluginManager].
  const PluginsPage({
    super.key,
    this.pluginManager,
  });

  /// Source of plugin data for this page.
  final PluginManager? pluginManager;

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  late final PluginManager _pluginManager;
  late final Future<void> _initializePlugins;

  @override
  void initState() {
    super.initState();
    _pluginManager = widget.pluginManager ?? PluginManager();
    _initializePlugins = _pluginManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Plugins'),
      ),
      body: FutureBuilder<void>(
        future: _initializePlugins,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Plugin> plugins = _pluginManager.plugins;

          if (plugins.isEmpty) {
            return const Center(child: Text('No plugins installed'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (BuildContext context, int index) {
              final Plugin plugin = plugins[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.extension),
                  title: Text(plugin.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Version ${plugin.version}'),
                      Text(plugin.enabled ? 'Enabled' : 'Disabled'),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 8),
            itemCount: plugins.length,
          );
        },
      ),
    );
  }
}
