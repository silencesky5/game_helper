import 'package:flutter/material.dart';

/// Minimal non-Windows shell used to prevent the automation dashboard from
/// running inside Android emulators.
class PlatformUnsupportedApp extends StatelessWidget {
  /// Creates a platform warning application shell.
  const PlatformUnsupportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Game Helper Desktop Required',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Game Helper Desktop Console runs on Windows only. '
              'Android emulators are controlled through ADB and must not host the dashboard.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
