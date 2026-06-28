abstract class DeviceService {
  Future<void> tap(int x, int y);

  Future<void> swipe(
    int startX,
    int startY,
    int endX,
    int endY,
    int duration,
  );

  Future<void> input(String text);

  Future<String> screenshot();
}