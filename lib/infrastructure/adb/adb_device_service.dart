import '../../domain/device/device.dart';
import '../../domain/device/device_service.dart';
import 'adb_command_runner.dart';

/// ADB-backed device service for Android automation.
class AdbDeviceService implements DeviceService {
  /// Creates an ADB-backed device service.
  const AdbDeviceService({this.commandRunner = const AdbCommandRunner()});

  /// Runner responsible for invoking adb.
  final AdbCommandRunner commandRunner;

  @override
  Future<List<Device>> getDevices() async {
    return const <Device>[];
  }

  /// Taps the screen at [x] and [y].
  @override
  Future<void> tap(int x, int y) async {
    await commandRunner.run(<String>['shell', 'input', 'tap', '$x', '$y']);
  }

  /// Swipes from the start coordinates to the end coordinates.
  @override
  Future<void> swipe(
    int startX,
    int startY,
    int endX,
    int endY,
    int duration,
  ) async {
    await commandRunner.run(<String>[
      'shell',
      'input',
      'swipe',
      '$startX',
      '$startY',
      '$endX',
      '$endY',
      '$duration',
    ]);
  }

  /// Inputs [text] on the connected device.
  @override
  Future<void> input(String text) async {
    await commandRunner.run(<String>['shell', 'input', 'text', text]);
  }

  /// Sends an Android key event for [keyCode].
  @override
  Future<void> keyEvent(int keyCode) async {
    await commandRunner.run(<String>['shell', 'input', 'keyevent', '$keyCode']);
  }

  /// Stubbed screenshot operation.
  @override
  Future<String> screenshot() async {
    return '';
  }

  /// Stubbed screen-size operation.
  @override
  Future<(int width, int height)> getScreenSize() async {
    return (width: 0, height: 0);
  }
}
