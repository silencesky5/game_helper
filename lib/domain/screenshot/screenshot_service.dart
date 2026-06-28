import '../core/result.dart';
import '../device/device.dart';
import 'device_screenshot.dart';

/// Captures Android screenshots without depending on Flutter UI types.
abstract class ScreenshotService {
  Future<Result<DeviceScreenshot>> capture(Device device);
}
