/// Describes an automation capability exposed by a game plugin.
class AutomationActionDefinition {
  /// Creates an immutable automation action definition.
  const AutomationActionDefinition({
    required this.id,
    required this.displayName,
    required this.category,
    this.description = '',
    this.defaultEnabled = false,
    this.settingsSchema = const <String, Object?>{},
  });

  /// Stable action identifier used by device automation config.
  final String id;

  /// User-facing action name shown by the dashboard.
  final String displayName;

  /// Category used to group generated UI sections.
  final String category;

  /// Optional help text for the action.
  final String description;

  /// Whether newly-created device configs enable this action by default.
  final bool defaultEnabled;

  /// Future-ready schema for advanced per-action settings.
  final Map<String, Object?> settingsSchema;
}
