import '../../domain/plugin/plugin_manifest.dart';

/// Parses plugin manifest data without handling workflow definitions.
class ManifestParser {
  /// Creates a manifest parser.
  const ManifestParser();

  /// Converts already-decoded manifest.json data into a domain manifest.
  PluginManifest parseManifest(Map<String, Object?> json) {
    return PluginManifest.fromJson(json);
  }
}
