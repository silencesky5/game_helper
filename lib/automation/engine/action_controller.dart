import 'dart:async';
import 'dart:math';

import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';
import '../../infrastructure/adb/adb_manager.dart';
import '../../emulator/emulator.dart';

/// Centralized emulator action API. Tasks must not operate ADB directly.
class ActionController {
  /// Creates an action controller.
  ActionController({Random? random, ADBManager? adbManager, this.logger})
      : _random = random ?? Random(),
        _adbManager = adbManager ?? ADBManager(logger: logger);

  final Random _random;
  final ADBManager _adbManager;
  final LoggerService? logger;

  Future<void> tap(Emulator emulator, int x, int y) async {
    _log('[ADB Tap]\nPosition\n$x,$y');
    await _adb(<String>['-s', emulator.id, 'shell', 'input', 'tap', '$x', '$y']);
  }

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
    await randomDelay(min: const Duration(milliseconds: 60), max: const Duration(milliseconds: 120));
    await tap(emulator, x, y);
  }

  Future<void> longPress(Emulator emulator, int x, int y) async {
    _log('[ADB Long Press]\nPosition\n$x,$y');
    await _adb(<String>['-s', emulator.id, 'shell', 'input', 'swipe', '$x', '$y', '$x', '$y', '700']);
  }

  Future<void> swipe(
    Emulator emulator,
    int startX,
    int startY,
    int endX,
    int endY,
  ) async {
    _log('[ADB Swipe]\nFrom\n$startX,$startY\nTo\n$endX,$endY');
    await _adb(<String>['-s', emulator.id, 'shell', 'input', 'swipe', '$startX', '$startY', '$endX', '$endY', '300']);
  }

  Future<void> back(Emulator emulator) async {
    _log('[ADB Back]');
    await _adb(<String>['-s', emulator.id, 'shell', 'input', 'keyevent', '4']);
  }

  Future<void> home(Emulator emulator) async {
    _log('[ADB Home]');
    await _adb(<String>['-s', emulator.id, 'shell', 'input', 'keyevent', '3']);
  }

  Future<void> launchGame(Emulator emulator, String packageName) async {
    _log('[ADB Launch]\nPackage\n$packageName');
    await _adb(<String>['-s', emulator.id, 'shell', 'monkey', '-p', packageName, '-c', 'android.intent.category.LAUNCHER', '1']);
  }

  Future<void> closeDialog(Emulator emulator) => back(emulator);

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

  Future<void> _adb(List<String> arguments) async {
    final result = await _adbManager.execute(arguments);
    if (result.exitCode != 0) {
      throw StateError('ADB command failed (${result.exitCode}): ${result.stderr}');
    }
  }

  void _log(String message) => logger?.log(LogLevel.info, message);
}
