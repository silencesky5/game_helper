import 'dart:typed_data';

/// Latest PNG screenshot captured for a device.
class DeviceScreenshot {
  const DeviceScreenshot({required this.deviceId, required this.pngBytes, required this.updatedAt, this.width, this.height});

  final String deviceId;
  final Uint8List pngBytes;
  final DateTime updatedAt;
  final int? width;
  final int? height;

  /// Dashboard-friendly dimensions when the PNG header could be read.
  String get sizeLabel => width == null || height == null ? 'Unknown' : '${width}x$height';
}
