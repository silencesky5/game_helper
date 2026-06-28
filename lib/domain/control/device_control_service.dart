import '../core/result.dart';
import '../device/device.dart';

/// Device control API used by actions and queues.
abstract class DeviceControlService {
  Future<Result<void>> tap(Device device, int x, int y);
  Future<Result<void>> swipe(Device device, int startX, int startY, int endX, int endY, {Duration duration = const Duration(milliseconds: 300)});
  Future<Result<void>> inputText(Device device, String text);
  Future<Result<void>> pressBack(Device device);
  Future<Result<void>> pressHome(Device device);
  Future<Result<void>> launchApp(Device device, String packageName, {String? activityName});
  Future<Result<void>> killApp(Device device, String packageName);
}
