import 'dart:io';

import 'adb_manager.dart';

/// Runs adb commands through the centralized ADB manager.
class AdbCommandRunner {
  /// Creates an adb command runner.
  const AdbCommandRunner({required this.adbManager});

  /// Centralized ADB process manager.
  final ADBManager adbManager;

  /// Runs adb with [arguments].
  Future<ProcessResult> run(List<String> arguments) {
    return adbManager.execute(arguments);
  }

  /// Runs adb and preserves stdout as raw bytes for binary commands.
  Future<ProcessResult> runBinary(List<String> arguments) {
    return adbManager.execute(arguments, binary: true);
  }
}
