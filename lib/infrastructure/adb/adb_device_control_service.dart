import 'dart:io';

import '../../domain/control/device_control_service.dart';
import '../../domain/core/result.dart';
import '../../domain/device/device.dart';
import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';
import 'adb_command_runner.dart';
import 'adb_manager.dart';

/// ADB-backed implementation of Android input and app lifecycle commands.
class AdbDeviceControlService implements DeviceControlService {
  AdbDeviceControlService({AdbCommandRunner? commandRunner, ADBManager? adbManager, this.logger})
      : commandRunner = commandRunner ?? AdbCommandRunner(adbManager: adbManager ?? ADBManager(logger: logger));

  final AdbCommandRunner commandRunner;
  final LoggerService? logger;

  @override
  Future<Result<void>> tap(Device device, int x, int y) => _shell(device, 'Tap', <String>['input', 'tap', '$x', '$y']);

  @override
  Future<Result<void>> swipe(Device device, int startX, int startY, int endX, int endY, {Duration duration = const Duration(milliseconds: 300)}) {
    return _shell(device, 'Swipe', <String>['input', 'swipe', '$startX', '$startY', '$endX', '$endY', '${duration.inMilliseconds}']);
  }

  @override
  Future<Result<void>> inputText(Device device, String text) => _shell(device, 'Input Text', <String>['input', 'text', text.replaceAll(' ', '%s')]);

  @override
  Future<Result<void>> pressBack(Device device) => _shell(device, 'Back', <String>['input', 'keyevent', 'KEYCODE_BACK']);

  @override
  Future<Result<void>> pressHome(Device device) => _shell(device, 'Home', <String>['input', 'keyevent', 'KEYCODE_HOME']);

  @override
  Future<Result<void>> launchApp(Device device, String packageName, {String? activityName}) {
    if (activityName != null) {
      return _shell(device, 'Launch App', <String>['am', 'start', '-n', '$packageName/$activityName']);
    }
    return _shell(device, 'Launch App', <String>['monkey', '-p', packageName, '-c', 'android.intent.category.LAUNCHER', '1']);
  }

  @override
  Future<Result<void>> killApp(Device device, String packageName) => _shell(device, 'Kill App', <String>['am', 'force-stop', packageName]);

  Future<Result<void>> _shell(Device device, String label, List<String> shellArgs) async {
    if (!device.isOnline) return Failure<void>(DeviceDisconnectedException('Device is not online: ${device.id}'));
    logger?.log(LogLevel.info, '[ADB] $label ${device.id}');
    try {
      final ProcessResult result = await commandRunner.run(<String>['-s', device.id, 'shell', ...shellArgs]);
      if (result.exitCode != 0) return Failure<void>(ADBCommandException('$label failed for ${device.id}', cause: result.stderr, exitCode: result.exitCode));
      return const Success<void>(null);
    } on ProcessException catch (error) {
      return Failure<void>(ADBCommandException('Unable to run adb $label', cause: error));
    }
  }
}
