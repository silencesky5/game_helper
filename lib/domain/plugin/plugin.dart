/// Immutable plugin metadata used by the platform UI and domain services.
class Plugin {
  /// Unique plugin identifier.
  final String id;

  /// Human-readable plugin name.
  final String name;

  /// Plugin semantic version string.
  final String version;

  /// Plugin author name.
  final String author;

  /// Short plugin description.
  final String description;

  /// Optional icon asset or symbolic icon identifier.
  final String icon;

  /// Whether the plugin is enabled in the platform.
  final bool enabled;

  /// Creates immutable plugin metadata.
  const Plugin({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    required this.icon,
    required this.enabled,
  });
}
