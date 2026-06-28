class AdbDeviceService implements DeviceService {
  @override
  Future<void> tap(int x, int y) async {}

  @override
  Future<void> swipe(
    int startX,
    int startY,
    int endX,
    int endY,
    int duration,
  ) async {}

  @override
  Future<void> input(String text) async {}

  @override
  Future<String> screenshot() async {
    return "";
  }
}