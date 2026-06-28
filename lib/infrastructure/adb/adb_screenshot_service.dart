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
  AdbScreenshotService({AdbCommandRunner? commandRunner, ADBManager? adbManager, this.logger})
      : commandRunner = commandRunner ?? AdbCommandRunner(adbManager: adbManager ?? ADBManager(logger: logger));

  final AdbCommandRunner commandRunner;
  final LoggerService? logger;

  @override
  Future<Result<DeviceScreenshot>> capture(Device device) async {
    if (!device.isOnline) {
      return Failure<DeviceScreenshot>(DeviceDisconnectedException('Device is not online: ${device.id}'));
    }
    logger?.log(LogLevel.info, '[ADB] Capture Screenshot ${device.id}');
    try {
      final ProcessResult result = await commandRunner.runBinary(<String>['-s', device.id, 'exec-out', 'screencap', '-p']);
      if (result.exitCode != 0) {
        return Failure<DeviceScreenshot>(ADBCommandException('Screenshot failed for ${device.id}', cause: result.stderr, exitCode: result.exitCode));
      }
      final Object stdout = result.stdout;
      final Uint8List bytes = stdout is Uint8List ? stdout : Uint8List.fromList(stdout.toString().codeUnits);
      if (bytes.isEmpty) {
        return Failure<DeviceScreenshot>(const ADBCommandException('Screenshot returned empty PNG'));
      }
      return Success<DeviceScreenshot>(DeviceScreenshot(deviceId: device.id, pngBytes: bytes, updatedAt: DateTime.now()));
    } on ProcessException catch (error) {
      return Failure<DeviceScreenshot>(ADBCommandException('Unable to run adb screencap', cause: error));
    }
  }
}
