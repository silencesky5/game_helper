/// Immutable value object describing a device screen size.
class ScreenSize {
  /// Creates an immutable screen-size value object.
  const ScreenSize({
    required this.width,
    required this.height,
  });

  /// Screen width in pixels.
  final int width;

  /// Screen height in pixels.
  final int height;
}
