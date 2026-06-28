import 'dart:io';

import '../engine/image_detector.dart';
import '../engine/popup_manager.dart';
import '../models/task_context.dart';

/// Scene-first navigation facade used by tasks.
///
/// Tasks must ask this service to move between scenes instead of issuing taps,
/// swipes, or other ADB actions directly.
class NavigationService {
  /// Creates the version-1 navigation service.
  const NavigationService({
    this.popupManager = const PopupManager(),
    this.unknownLogger = const UnknownSceneLogger(),
  });

  /// Global popup handler used during login navigation.
  final PopupManager popupManager;

  /// Diagnostic logger for scenes that remain unknown after retries.
  final UnknownSceneLogger unknownLogger;

  /// Returns to Home from any supported v1 launch state.
  Future<bool> goHome(TaskContext context) async {
    final scene = await context.stateManager.detectScene();
    if (scene == Scene.home || await context.stateManager.isHomeScene()) {
      return true;
    }
    if (scene == Scene.android) {
      if (!await launchGame(context)) return false;
    }
    if (!await waitLoading(context)) return false;
    return waitHome(context);
  }

  /// Launches GrowStone from the Android desktop by random-tapping the icon.
  Future<bool> launchGame(TaskContext context) async {
    final iconRect = await context.stateManager.imageDetector.findTemplateRect(
      VisionTemplates.androidGrowstoneIcon,
    );
    if (iconRect == null) {
      context.log('Navigation launchGame failed: GrowStone icon not found');
      return false;
    }

    await context.actionController.randomTap(context.emulator, iconRect);
    return context.actionController.waitSceneChange(
      () async {
        final scene = await context.stateManager.detectScene();
        return scene == Scene.loading ||
            scene == Scene.attendance ||
            scene == Scene.home;
      },
      timeout: const Duration(seconds: 10),
      interval: const Duration(milliseconds: 300),
    );
  }

  /// Waits until the loading scene has ended. Loading is read-only.
  Future<bool> waitLoading(TaskContext context) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      final scene = await context.stateManager.detectScene();
      if (scene != Scene.loading) return true;
      await context.actionController.randomDelay(
        min: const Duration(milliseconds: 500),
        max: const Duration(milliseconds: 1000),
      );
    }
    context.log('Navigation waitLoading timed out after 30 seconds');
    return false;
  }

  /// Waits for Home, handling login popups and never acting on unknown scenes.
  Future<bool> waitHome(TaskContext context) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    var unknownRetries = 0;
    while (DateTime.now().isBefore(deadline)) {
      final scene = await context.stateManager.detectScene();
      if (scene == Scene.home) {
        return true;
      }
      if (scene == Scene.attendance) {
        await closePopup(context);
        unknownRetries = 0;
        continue;
      }
      if (scene == Scene.loading) {
        await context.actionController.randomDelay(
          min: const Duration(milliseconds: 500),
          max: const Duration(milliseconds: 1000),
        );
        unknownRetries = 0;
        continue;
      }
      if (scene == Scene.unknown) {
        unknownRetries += 1;
        if (unknownRetries >= 4) {
          await unknownLogger.save(context);
          return false;
        }
        await context.actionController.wait(const Duration(milliseconds: 500));
        continue;
      }

      await context.actionController.wait(const Duration(milliseconds: 300));
      unknownRetries = 0;
    }
    context.log('Navigation waitHome timed out after 60 seconds');
    return false;
  }

  /// Waits until [target] is detected and returns the last observed scene.
  Future<Scene> waitScene(TaskContext context, Scene target) async {
    var current = Scene.unknown;
    await context.actionController.waitSceneChange(
      () async {
        current = await context.stateManager.detectScene();
        return current == target;
      },
      timeout: const Duration(seconds: 30),
      interval: const Duration(milliseconds: 300),
    );
    return current;
  }

  /// Sends an Android back action through the central action controller.
  Future<void> back(TaskContext context) =>
      context.actionController.back(context.emulator);

  /// Handles the highest-priority current popup, if any.
  Future<void> closePopup(TaskContext context) async {
    final result = await popupManager.checkAndHandle(context);
    context.log('Popup handler: ${result.message}');
  }
}

/// Saves diagnostics when a scene remains unknown.
class UnknownSceneLogger {
  /// Creates an unknown scene logger rooted at [rootDirectory].
  const UnknownSceneLogger({this.rootDirectory = 'logs/screenshots'});

  /// Root screenshot directory.
  final String rootDirectory;

  /// Writes a timestamped placeholder diagnostic for the unknown scene.
  Future<File> save(TaskContext context) async {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final date = '${now.year}-${two(now.month)}-${two(now.day)}';
    final time = '${two(now.hour)}-${two(now.minute)}-${two(now.second)}';
    final directory = Directory('$rootDirectory/$date')
      ..createSync(recursive: true);
    final file = File('${directory.path}/${time}_unknown.png');
    await file.writeAsBytes(const <int>[]);
    context.log('Unknown scene screenshot saved: ${file.path}');
    return file;
  }
}
