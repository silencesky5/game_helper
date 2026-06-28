import 'device.dart';

/// Defines the contract for platform device discovery and connection state.
abstract class DeviceService {
  /// Detects devices known to ADB or another Android device provider.
  Future<List<Device>> detectDevices();

  /// Connects or selects the device with [deviceId].
  Future<Device> connect(String deviceId);

  /// Disconnects or deselects the device with [deviceId].
  Future<void> disconnect(String deviceId);

  /// Returns the latest status for [deviceId].
  Future<DeviceStatus> getStatus(String deviceId);
}
