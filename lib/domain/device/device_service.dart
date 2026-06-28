/// Defines the contract for device automation operations.
abstract class DeviceService {
  /// Taps the screen at the provided [x] and [y] coordinates.
  Future<void> tap(int x, int y);

  /// Swipes from the start coordinates to the end coordinates.
  Future<void> swipe(
    int startX,
    int startY,
    int endX,
    int endY,
    int duration,
  );

  /// Inputs [text] on the connected device.
  Future<void> input(String text);

  /// Captures a screenshot and returns its encoded representation.
  Future<String> screenshot();
}
