import 'device_screenshot.dart';

/// In-memory cache for the latest screenshot per device.
class ScreenshotRepository {
  final Map<String, DeviceScreenshot> _screenshots = <String, DeviceScreenshot>{};

  DeviceScreenshot? latest(String deviceId) => _screenshots[deviceId];

  List<DeviceScreenshot> get all => List<DeviceScreenshot>.unmodifiable(_screenshots.values);

  void save(DeviceScreenshot screenshot) {
    _screenshots[screenshot.deviceId] = screenshot;
  }

  void remove(String deviceId) {
    _screenshots.remove(deviceId);
  }

  void clear() {
    _screenshots.clear();
  }
}
