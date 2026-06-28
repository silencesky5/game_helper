import 'dart:typed_data';

/// Latest PNG screenshot captured for a device.
class DeviceScreenshot {
  const DeviceScreenshot({required this.deviceId, required this.pngBytes, required this.updatedAt});

  final String deviceId;
  final Uint8List pngBytes;
  final DateTime updatedAt;
}
