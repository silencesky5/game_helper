/// Immutable representation of a plugin manifest file.
class PluginManifest {
  /// Unique plugin identifier.
  final String id;

  /// Internal plugin implementation name.
  final String name;

  /// Localized user-facing plugin display name.
  final String displayName;

  /// Plugin semantic version string.
  final String version;

  /// Plugin author name.
  final String author;

  /// Short plugin description.
  final String description;

  /// Creates immutable plugin manifest metadata.
  const PluginManifest({
    required this.id,
    required this.name,
    String? displayName,
    required this.version,
    required this.author,
    required this.description,
  }) : displayName = displayName ?? name;

  /// Creates a manifest from decoded JSON data.
  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] as String?) ?? json['name'] as String,
      version: json['version'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
    );
  }

  /// Converts this manifest to JSON-compatible data.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'displayName': displayName,
      'version': version,
      'author': author,
      'description': description,
    };
  }
}
