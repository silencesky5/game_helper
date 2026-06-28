import 'package:flutter/material.dart';

import '../presentation/dashboard/dashboard_page.dart';
import 'theme.dart';

/// Root widget for the Game Helper application.
class GameHelperApp extends StatelessWidget {
  /// Creates the root Game Helper application widget.
  const GameHelperApp({super.key});

  /// Builds the root application shell.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Helper',
      theme: GameHelperTheme.dark(),
      home: const DashboardPage(),
    );
  }
}
