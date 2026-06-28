import 'device.dart';
import 'screen_size.dart';

/// Defines the contract for device automation operations.
abstract class DeviceService {
  /// Returns devices known to the device layer.
  Future<List<Device>> getDevices();

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

  /// Sends an Android key event for [keyCode].
  Future<void> keyEvent(int keyCode);

  /// Captures a screenshot and returns its encoded representation.
  Future<String> screenshot();

  /// Returns the current screen width and height.
  Future<ScreenSize> getScreenSize();
}
