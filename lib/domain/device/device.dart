/// Connection state for an Android device known by the platform.
enum DeviceStatus {
  /// ADB reports the device is available.
  online,

  /// ADB reports the device is unavailable/offline.
  offline,

  /// ADB reports the device requires authorization.
  unauthorized,

  /// ADB did not provide a recognized state.
  unknown,
}

/// Represents an Android device known to the device layer.
class Device {
  /// Creates an immutable device model.
  const Device({
    required this.id,
    required this.name,
    required this.status,
    this.model = 'Unknown',
    this.androidVersion = 'Unknown',
  });

  /// Unique device identifier reported by the device provider.
  final String id;

  /// Human-readable device name.
  final String name;

  /// Device model identifier.
  final String model;

  /// Android OS version running on the device.
  final String androidVersion;

  /// Current device connection status.
  final DeviceStatus status;

  /// Whether the device is currently online and available for session work.
  bool get isOnline => status == DeviceStatus.online;

  /// Returns a copy with selected fields replaced.
  Device copyWith({
    String? id,
    String? name,
    String? model,
    String? androidVersion,
    DeviceStatus? status,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      androidVersion: androidVersion ?? this.androidVersion,
      status: status ?? this.status,
    );
  }
}
