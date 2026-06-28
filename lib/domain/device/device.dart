/// Represents an Android device known to the device layer.
class Device {
  /// Creates an immutable device model.
  const Device({
    required this.id,
    required this.name,
    required this.model,
    required this.androidVersion,
    required this.isOnline,
  });

  /// Unique device identifier reported by the device provider.
  final String id;

  /// Human-readable device name.
  final String name;

  /// Device model identifier.
  final String model;

  /// Android OS version running on the device.
  final String androidVersion;

  /// Whether the device is currently online and available for commands.
  final bool isOnline;
}
