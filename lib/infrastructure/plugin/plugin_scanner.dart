/// Stub for future plugin scanning behavior.
class PluginScanner {
  /// Creates a plugin scanner stub.
  const PluginScanner();

  /// Returns no plugin paths until filesystem scanning is implemented.
  Future<List<String>> scan() async {
    return const <String>[];
  }
}
