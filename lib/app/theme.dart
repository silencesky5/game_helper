import 'package:flutter/material.dart';

/// Application-wide desktop theme.
class GameHelperTheme {
  /// Dark console-oriented theme for the desktop dashboard.
  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.tealAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(8),
      ),
    );
  }
}
