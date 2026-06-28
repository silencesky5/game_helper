import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/platform_unsupported_app.dart';

/// Starts the Game Helper application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrap();

  runApp(
    !kIsWeb && Platform.isWindows ? const GameHelperApp() : const PlatformUnsupportedApp(),
  );
}
