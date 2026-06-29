import 'dart:convert';

import 'automation_action.dart';

/// Per-device automation logic selected by the user.
class AutomationConfig {
  /// Creates an immutable per-device automation config.
  const AutomationConfig({required this.deviceId, required this.enabledActions, this.priorityOrder = const <String>[]});

  /// Device this config belongs to.
  final String deviceId;

  /// Action enabled flags keyed by automation action id.
  final Map<String, bool> enabledActions;

  /// User-defined task priority order. Unknown new actions are appended by plugin defaults.
  final List<String> priorityOrder;

  /// Builds defaults from plugin-provided action definitions.
  factory AutomationConfig.defaultsFor(String deviceId, List<AutomationActionDefinition> actions) {
    return AutomationConfig(
      deviceId: deviceId,
      enabledActions: <String, bool>{for (final action in actions) action.id: action.defaultEnabled},
      priorityOrder: <String>[for (final action in actions) action.id],
    );
  }

  /// Restores a config from JSON and merges in definitions added by the plugin.
  factory AutomationConfig.fromJson(String deviceId, String? rawJson, List<AutomationActionDefinition> actions) {
    final defaults = AutomationConfig.defaultsFor(deviceId, actions).enabledActions;
    if (rawJson == null || rawJson.trim().isEmpty) {
      return AutomationConfig(deviceId: deviceId, enabledActions: defaults, priorityOrder: <String>[for (final action in actions) action.id]);
    }
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final saved = (decoded['enabledActions'] as Map<String, dynamic>? ?? <String, dynamic>{}).map(
      (String key, dynamic value) => MapEntry<String, bool>(key, value == true),
    );
    final savedOrder = (decoded['priorityOrder'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .where(defaults.containsKey)
        .toList(growable: true);
    for (final action in actions) {
      if (!savedOrder.contains(action.id)) savedOrder.add(action.id);
    }
    return AutomationConfig(deviceId: deviceId, enabledActions: <String, bool>{...defaults, ...saved}, priorityOrder: savedOrder);
  }

  /// Returns whether an action is enabled.
  bool isEnabled(String actionId) => enabledActions[actionId] ?? false;

  /// Returns a copy with one action toggled.
  AutomationConfig toggle(String actionId, bool enabled) {
    return AutomationConfig(deviceId: deviceId, enabledActions: <String, bool>{...enabledActions, actionId: enabled}, priorityOrder: priorityOrder);
  }

  /// Returns a copy with every known action set to [enabled].
  AutomationConfig setAll(Iterable<AutomationActionDefinition> actions, bool enabled) {
    return AutomationConfig(
      deviceId: deviceId,
      enabledActions: <String, bool>{for (final action in actions) action.id: enabled},
      priorityOrder: <String>[for (final action in actions) action.id],
    );
  }

  /// Returns a copy with a new priority order.
  AutomationConfig reorder(String actionId, int newIndex) {
    final order = priorityOrder.toList(growable: true);
    final oldIndex = order.indexOf(actionId);
    if (oldIndex < 0) return this;
    final item = order.removeAt(oldIndex);
    final index = newIndex.clamp(0, order.length).toInt();
    order.insert(index, item);
    return AutomationConfig(deviceId: deviceId, enabledActions: enabledActions, priorityOrder: order);
  }

  /// Encodes this config for platform storage.
  String toJson() => jsonEncode(<String, Object?>{'deviceId': deviceId, 'enabledActions': enabledActions, 'priorityOrder': priorityOrder});
}
