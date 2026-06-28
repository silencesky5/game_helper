/// Defines supported log severity levels for the platform.
enum LogLevel {
  /// Diagnostic information intended for development-time inspection.
  debug,

  /// General informational messages about normal platform behavior.
  info,

  /// Recoverable conditions that may require attention.
  warning,

  /// Error conditions that should be investigated.
  error,
}
