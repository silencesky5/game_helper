import 'dart:io';

/// Runs adb commands for the infrastructure device implementation.
class AdbCommandRunner {
  /// Creates an adb command runner.
  const AdbCommandRunner({this.executable = 'adb'});

  /// ADB executable path or command name.
  final String executable;

  /// Runs adb with [arguments].
  Future<ProcessResult> run(List<String> arguments) {
    return Process.run(executable, arguments);
  }
}
