import 'dart:io';
import 'dart:typed_data';

import '../../domain/core/result.dart';
import '../../domain/device/device.dart';
import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';
import '../../domain/screenshot/device_screenshot.dart';
import '../../domain/screenshot/screenshot_service.dart';
import 'adb_command_runner.dart';
import 'adb_manager.dart';

/// ADB implementation of screenshot capture using exec-out screencap -p.
class AdbScreenshotService implements ScreenshotService {
  AdbScreenshotService({AdbCommandRunner? commandRunner, ADBManager? adbManager, this.logger, this.maxAttempts = 3})
      : commandRunner = commandRunner ?? AdbCommandRunner(adbManager: adbManager ?? ADBManager(logger: logger));

  final AdbCommandRunner commandRunner;
  final LoggerService? logger;
  final int maxAttempts;

  @override
  Future<Result<DeviceScreenshot>> capture(Device device) async {
    if (!device.isOnline) {
      return Failure<DeviceScreenshot>(DeviceDisconnectedException('Device Offline: ${device.id}'));
    }

    ADBCommandException? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      logger?.log(LogLevel.info, '[ADB Screenshot] Capture ${device.id} attempt $attempt/$maxAttempts');
      try {
        final ProcessResult result = await commandRunner.runBinary(<String>['-s', device.id, 'exec-out', 'screencap', '-p']);
        if (result.exitCode != 0) {
          lastError = ADBCommandException('Device Offline: screenshot failed for ${device.id}', cause: result.stderr, exitCode: result.exitCode);
          continue;
        }
        final Uint8List bytes = _stdoutBytes(result.stdout);
        if (bytes.isEmpty) {
          lastError = const ADBCommandException('Capture Failed: Screenshot Empty');
          continue;
        }
        final (int? width, int? height) = _pngDimensions(bytes);
        final screenshot = DeviceScreenshot(deviceId: device.id, pngBytes: bytes, updatedAt: DateTime.now(), width: width, height: height);
        logger?.log(LogLevel.info, '[ADB Screenshot] Success ${screenshot.sizeLabel}');
        return Success<DeviceScreenshot>(screenshot);
      } on ProcessException catch (error) {
        lastError = ADBCommandException('Device Offline: unable to run adb screencap', cause: error);
      }
    }
    return Failure<DeviceScreenshot>(lastError ?? const ADBCommandException('Capture Failed'));
  }

  Uint8List _stdoutBytes(Object? stdout) {
    if (stdout is Uint8List) return stdout;
    if (stdout is List<int>) return Uint8List.fromList(stdout);
    return Uint8List.fromList(stdout.toString().codeUnits);
  }

  (int?, int?) _pngDimensions(Uint8List bytes) {
    const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length < 24) return (null, null);
    for (var i = 0; i < pngSignature.length; i++) {
      if (bytes[i] != pngSignature[i]) return (null, null);
    }
    int readUint32(int offset) => bytes.buffer.asByteData(bytes.offsetInBytes + offset, 4).getUint32(0);
    return (readUint32(16), readUint32(20));
  }
}
