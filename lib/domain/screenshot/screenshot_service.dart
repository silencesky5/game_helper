import 'dart:io';

import '../core/result.dart';
import '../device/device.dart';
import 'device_screenshot.dart';

/// Single source of truth for Android screenshots used by vision, dashboard,
/// debug overlays, and automation tasks.
abstract class ScreenshotService {
  /// Captures the current device screen as PNG bytes kept in memory.
  Future<Result<DeviceScreenshot>> capture(Device device);

  /// Captures the screenshot intended for dashboard preview.
  Future<Result<DeviceScreenshot>> capturePreview(Device device) => capture(device);

  /// Captures the screenshot intended for vision processing.
  Future<Result<DeviceScreenshot>> captureForVision(Device device) => capture(device);

  /// Captures the current screen and writes it to [file] for explicit debug use.
  Future<Result<DeviceScreenshot>> captureToFile(Device device, File file) async {
    final result = await capture(device);
    return result.fold((screenshot) async {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(screenshot.pngBytes, flush: true);
      return Success<DeviceScreenshot>(screenshot);
    }, (error) async => Failure<DeviceScreenshot>(error));
  }
}
