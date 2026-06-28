/// Holds in-memory state for a workflow execution.
class WorkflowRuntime {
  /// Runtime variables available to workflow steps during execution.
  final Map<String, Object?> variables;

  /// Creates an empty workflow runtime.
  WorkflowRuntime() : variables = <String, Object?>{};

  /// Stores [value] under [key] in the runtime variable map.
  void setVariable(String key, Object? value) {
    variables[key] = value;
  }

  /// Returns the variable stored under [key], or null when it is absent.
  Object? getVariable(String key) {
    return variables[key];
  }

  /// Returns true when a variable exists for [key].
  bool containsVariable(String key) {
    return variables.containsKey(key);
  }

  /// Removes and returns the variable stored under [key].
  Object? removeVariable(String key) {
    return variables.remove(key);
  }

  /// Removes all runtime variables from memory.
  void clear() {
    variables.clear();
  }
}
