import 'package:flutter/material.dart';

import '../../domain/plugin/plugin.dart';
import '../../domain/plugin/plugin_manager.dart';
import '../../app/localization/l10n_extension.dart';

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
        title: Text(context.l10n.installedPlugins),
      ),
      body: FutureBuilder<void>(
        future: _initializePlugins,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Plugin> plugins = _pluginManager.plugins;

          if (plugins.isEmpty) {
            return Center(child: Text(context.l10n.noPluginsInstalled));
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
                      Text(context.l10n.version(plugin.version)),
                      Text(plugin.enabled ? context.l10n.enabled : context.l10n.disabled),
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
