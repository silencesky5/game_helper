import '../../domain/device/device_service.dart';

/// ADB-backed device service stub for the platform foundation.
class AdbDeviceService implements DeviceService {
  /// Stubbed tap operation at [x] and [y].
  @override
  Future<void> tap(int x, int y) async {}

  /// Stubbed swipe operation between the provided coordinates.
  @override
  Future<void> swipe(
    int startX,
    int startY,
    int endX,
    int endY,
    int duration,
  ) async {}

  /// Stubbed text input operation for [text].
  @override
  Future<void> input(String text) async {}

  /// Stubbed screenshot operation.
  @override
  Future<String> screenshot() async {
    return '';
  }
}
