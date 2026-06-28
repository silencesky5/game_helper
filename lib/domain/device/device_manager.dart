import 'device.dart';
import 'device_service.dart';

/// Coordinates device state for callers without exposing implementation details.
class DeviceManager {
  /// Creates a device manager backed by [deviceService].
  DeviceManager(this.deviceService);

  /// Device service used for all device operations.
  final DeviceService deviceService;

  Device? _currentDevice;

  /// The currently selected device, if one has been initialized.
  Device? get currentDevice => _currentDevice;

  /// Initializes device state from the configured [deviceService].
  Future<void> initialize() async {
    final devices = await deviceService.getDevices();
    _currentDevice = devices.where((device) => device.isOnline).firstOrNull;
  }

  /// Sets the current device explicitly.
  void setCurrentDevice(Device device) {
    _currentDevice = device;
  }

  /// Clears the selected device.
  void clearCurrentDevice() {
    _currentDevice = null;
  }
}
