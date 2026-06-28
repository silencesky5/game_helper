import 'dart:convert';
import 'dart:io';

/// Runtime settings for the desktop device monitor.
class DesktopConsoleConfig {
  /// Creates desktop console settings.
  const DesktopConsoleConfig({this.screenshotRefreshIntervalMs = 1000});

  /// Screenshot polling interval for each online ADB session.
  final int screenshotRefreshIntervalMs;

  /// Loads settings from config/desktop_console.json when available.
  static DesktopConsoleConfig loadSync() {
    try {
      final file = File('config/desktop_console.json');
      if (!file.existsSync()) return const DesktopConsoleConfig();
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final interval = json['screenshotRefreshIntervalMs'] as int? ?? 1000;
      return DesktopConsoleConfig(screenshotRefreshIntervalMs: interval.clamp(500, 1000));
    } on Object {
      return const DesktopConsoleConfig();
    }
  }

  /// Polling duration clamped to the sprint's 500ms-1000ms requirement.
  Duration get screenshotRefreshInterval => Duration(milliseconds: screenshotRefreshIntervalMs.clamp(500, 1000));
}
