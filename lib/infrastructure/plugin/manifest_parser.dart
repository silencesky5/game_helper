import '../../domain/plugin/plugin_manifest.dart';

/// Stub for future plugin manifest parsing behavior.
class ManifestParser {
  /// Creates a manifest parser stub.
  const ManifestParser();

  /// Converts already-decoded manifest data into a domain manifest.
  PluginManifest parse(Map<String, dynamic> json) {
    return PluginManifest.fromJson(json);
  }
}
