import 'dart:async';

import '../../emulator/emulator.dart';

/// Centralized emulator action API. Tasks must not operate ADB directly.
class ActionController {
  /// Creates an action controller.
  const ActionController();

  Future<void> tap(Emulator emulator, int x, int y) async {}
  Future<void> doubleTap(Emulator emulator, int x, int y) async { await tap(emulator, x, y); await tap(emulator, x, y); }
  Future<void> longPress(Emulator emulator, int x, int y) async {}
  Future<void> swipe(Emulator emulator, int startX, int startY, int endX, int endY) async {}
  Future<void> back(Emulator emulator) async {}
  Future<void> home(Emulator emulator) async {}
  Future<void> launchGame(Emulator emulator, String packageName) async {}
  Future<void> closeDialog(Emulator emulator) async {}
  Future<void> wait(Duration duration) => Future<void>.delayed(duration);
}
