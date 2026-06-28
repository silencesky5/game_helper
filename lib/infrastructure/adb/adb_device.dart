import '../../domain/device/device.dart';

/// Android device representation used by the ADB infrastructure layer.
class AdbDevice extends Device {
  /// Creates an immutable ADB device model.
  const AdbDevice({
    required super.id,
    required super.name,
    required super.model,
    required super.androidVersion,
    required super.isOnline,
  });
}
