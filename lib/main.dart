import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

/// Starts the Game Helper application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrap();

  runApp(
    const GameHelperApp(),
  );
}
