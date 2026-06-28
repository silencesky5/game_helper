/// Runtime lifecycle states for an automation session.
enum AutomationState {
  /// No automation has been started for the session.
  idle,

  /// The session has been requested to run.
  running,

  /// The session has been paused.
  paused,

  /// The session has been stopped.
  stopped,

  /// The session completed successfully.
  completed,

  /// The session failed.
  failed,
}
