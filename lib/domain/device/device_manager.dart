import 'device.dart';
import 'device_service.dart';

/// Coordinates device discovery, connection, and status for callers.
class DeviceManager {
  /// Creates a device manager backed by [deviceService].
  DeviceManager(this.deviceService);

  /// Device service used for all device operations.
  final DeviceService deviceService;

  final Map<String, Device> _devices = <String, Device>{};

  /// Last detected devices.
  List<Device> get devices => List<Device>.unmodifiable(_devices.values);

  /// Detects ADB devices and stores the latest snapshot.
  Future<List<Device>> detectDevices() async {
    final List<Device> detectedDevices = await deviceService.detectDevices();
    _devices
      ..clear()
      ..addEntries(
        detectedDevices.map((Device device) => MapEntry<String, Device>(device.id, device)),
      );
    return devices;
  }

  /// Connects to a device and updates its stored status.
  Future<Device> connect(String deviceId) async {
    final Device device = await deviceService.connect(deviceId);
    _devices[device.id] = device;
    return device;
  }

  /// Disconnects from a device and marks it offline locally.
  Future<void> disconnect(String deviceId) async {
    await deviceService.disconnect(deviceId);
    final Device? device = _devices[deviceId];
    if (device != null) {
      _devices[deviceId] = device.copyWith(status: DeviceStatus.offline);
    }
  }

  /// Returns the latest device status from the underlying service.
  Future<DeviceStatus> getStatus(String deviceId) async {
    final DeviceStatus status = await deviceService.getStatus(deviceId);
    final Device? device = _devices[deviceId];
    if (device != null) {
      _devices[deviceId] = device.copyWith(status: status);
    }
    return status;
  }
}
