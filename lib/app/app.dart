import 'package:flutter/material.dart';

/// Root widget for the Game Helper application.
class GameHelperApp extends StatelessWidget {
  /// Creates the root Game Helper application widget.
  const GameHelperApp({super.key});

  /// Builds the root application shell.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SizedBox.shrink(),
    );
  }
}
