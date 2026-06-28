import 'device_screenshot.dart';

/// In-memory cache for the latest screenshot per device.
class ScreenshotRepository {
  final Map<String, DeviceScreenshot> _screenshots = <String, DeviceScreenshot>{};
  final Map<String, DeviceScreenshot> _previousScreenshots = <String, DeviceScreenshot>{};

  DeviceScreenshot? latest(String deviceId) => _screenshots[deviceId];

  DeviceScreenshot? previous(String deviceId) => _previousScreenshots[deviceId];

  List<DeviceScreenshot> get all => List<DeviceScreenshot>.unmodifiable(_screenshots.values);

  void save(DeviceScreenshot screenshot) {
    final current = _screenshots[screenshot.deviceId];
    if (current != null) _previousScreenshots[screenshot.deviceId] = current;
    _screenshots[screenshot.deviceId] = screenshot;
  }

  void remove(String deviceId) {
    _screenshots.remove(deviceId);
    _previousScreenshots.remove(deviceId);
  }

  void clear() {
    _screenshots.clear();
    _previousScreenshots.clear();
  }
}
