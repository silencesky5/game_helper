import 'dart:async';
import 'dart:math';

import '../../emulator/emulator.dart';

/// Centralized emulator action API. Tasks must not operate ADB directly.
class ActionController {
  /// Creates an action controller.
  ActionController({Random? random}) : _random = random ?? Random();

  final Random _random;

  Future<void> tap(Emulator emulator, int x, int y) async {}

  /// Taps a random point inside [rect] to avoid fixed-coordinate behavior.
  Future<void> randomTap(Emulator emulator, Rectangle<int> rect) async {
    final x = rect.left + _random.nextInt(max(1, rect.width));
    final y = rect.top + _random.nextInt(max(1, rect.height));
    await tap(emulator, x, y);
    await randomDelay(
      min: const Duration(milliseconds: 250),
      max: const Duration(milliseconds: 450),
    );
  }

  Future<void> doubleTap(Emulator emulator, int x, int y) async {
    await tap(emulator, x, y);
    await tap(emulator, x, y);
  }

  Future<void> longPress(Emulator emulator, int x, int y) async {}
  Future<void> swipe(
    Emulator emulator,
    int startX,
    int startY,
    int endX,
    int endY,
  ) async {}
  Future<void> back(Emulator emulator) async {}
  Future<void> home(Emulator emulator) async {}
  Future<void> launchGame(Emulator emulator, String packageName) async {}
  Future<void> closeDialog(Emulator emulator) async {}

  /// Waits for a random duration in the inclusive [min] to [max] range.
  Future<void> randomDelay({required Duration min, required Duration max}) {
    final spread = max.inMilliseconds - min.inMilliseconds;
    final millis = min.inMilliseconds +
        (spread <= 0 ? 0 : _random.nextInt(spread + 1));
    return wait(Duration(milliseconds: millis));
  }

  /// Polls until a scene-changing predicate returns true or the timeout elapses.
  Future<bool> waitSceneChange(
    Future<bool> Function() changed, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await changed()) {
        return true;
      }
      await wait(interval);
    }
    return false;
  }

  Future<void> wait(Duration duration) => Future<void>.delayed(duration);
}
