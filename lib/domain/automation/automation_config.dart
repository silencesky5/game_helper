import 'dart:convert';

import 'automation_action.dart';

/// Per-device automation logic selected by the user.
class AutomationConfig {
  /// Creates an immutable per-device automation config.
  const AutomationConfig({required this.deviceId, required this.enabledActions});

  /// Device this config belongs to.
  final String deviceId;

  /// Action enabled flags keyed by automation action id.
  final Map<String, bool> enabledActions;

  /// Builds defaults from plugin-provided action definitions.
  factory AutomationConfig.defaultsFor(String deviceId, List<AutomationActionDefinition> actions) {
    return AutomationConfig(
      deviceId: deviceId,
      enabledActions: <String, bool>{for (final action in actions) action.id: action.defaultEnabled},
    );
  }

  /// Restores a config from JSON and merges in definitions added by the plugin.
  factory AutomationConfig.fromJson(String deviceId, String? rawJson, List<AutomationActionDefinition> actions) {
    final defaults = AutomationConfig.defaultsFor(deviceId, actions).enabledActions;
    if (rawJson == null || rawJson.trim().isEmpty) {
      return AutomationConfig(deviceId: deviceId, enabledActions: defaults);
    }
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final saved = (decoded['enabledActions'] as Map<String, dynamic>? ?? <String, dynamic>{}).map(
      (String key, dynamic value) => MapEntry<String, bool>(key, value == true),
    );
    return AutomationConfig(deviceId: deviceId, enabledActions: <String, bool>{...defaults, ...saved});
  }

  /// Returns whether an action is enabled.
  bool isEnabled(String actionId) => enabledActions[actionId] ?? false;

  /// Returns a copy with one action toggled.
  AutomationConfig toggle(String actionId, bool enabled) {
    return AutomationConfig(deviceId: deviceId, enabledActions: <String, bool>{...enabledActions, actionId: enabled});
  }

  /// Returns a copy with every known action set to [enabled].
  AutomationConfig setAll(Iterable<AutomationActionDefinition> actions, bool enabled) {
    return AutomationConfig(deviceId: deviceId, enabledActions: <String, bool>{for (final action in actions) action.id: enabled});
  }

  /// Encodes this config for platform storage.
  String toJson() => jsonEncode(<String, Object?>{'deviceId': deviceId, 'enabledActions': enabledActions});
}
