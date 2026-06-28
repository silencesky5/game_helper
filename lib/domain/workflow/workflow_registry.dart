/// Registry for known workflow step type identifiers.
class WorkflowRegistry {
  final Set<String> _types;

  /// Creates an empty workflow registry.
  WorkflowRegistry() : _types = <String>{};

  /// Registers the platform default workflow step type identifiers.
  void registerDefaultSteps() {
    register('tap');
    register('swipe');
    register('delay');
    register('wait');
    register('ocr');
    register('if');
    register('loop');
  }

  /// Registers a workflow step [type].
  void register(String type) {
    _types.add(type);
  }

  /// Unregisters a workflow step [type].
  void unregister(String type) {
    _types.remove(type);
  }

  /// Returns true when [type] has been registered.
  bool contains(String type) {
    return _types.contains(type);
  }

  /// Removes all registered workflow step types.
  void clear() {
    _types.clear();
  }
}
