import 'device_screenshot.dart';

/// In-memory cache for the latest screenshot per device plus debug history.
class ScreenshotRepository {
  ScreenshotRepository({this.historyLimit = 10});

  final int historyLimit;
  final Map<String, DeviceScreenshot> _screenshots = <String, DeviceScreenshot>{};
  final Map<String, DeviceScreenshot> _previousScreenshots = <String, DeviceScreenshot>{};
  final Map<String, List<DeviceScreenshot>> _history = <String, List<DeviceScreenshot>>{};

  DeviceScreenshot? latest(String deviceId) => _screenshots[deviceId];

  DeviceScreenshot? previous(String deviceId) => _previousScreenshots[deviceId];

  List<DeviceScreenshot> history(String deviceId) => List<DeviceScreenshot>.unmodifiable(_history[deviceId] ?? const <DeviceScreenshot>[]);

  List<DeviceScreenshot> get all => List<DeviceScreenshot>.unmodifiable(_screenshots.values);

  void save(DeviceScreenshot screenshot) {
    final current = _screenshots[screenshot.deviceId];
    if (current != null) _previousScreenshots[screenshot.deviceId] = current;
    _screenshots[screenshot.deviceId] = screenshot;
    final history = _history.putIfAbsent(screenshot.deviceId, () => <DeviceScreenshot>[]);
    history.add(screenshot);
    while (history.length > historyLimit) {
      history.removeAt(0);
    }
  }

  void remove(String deviceId) {
    _screenshots.remove(deviceId);
    _previousScreenshots.remove(deviceId);
    _history.remove(deviceId);
  }

  void clear() {
    _screenshots.clear();
    _previousScreenshots.clear();
    _history.clear();
  }
}
