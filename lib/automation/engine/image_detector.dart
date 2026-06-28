import 'dart:math';

/// Central image-recognition facade for OpenCV, OCR, and template matching.
class ImageDetector {
  /// Creates an image detector placeholder.
  const ImageDetector();

  /// Finds a named UI template on the current emulator screen.
  Future<bool> findTemplate(String templateId) async => false;

  /// Finds the screen rectangle occupied by a named template.
  Future<Rectangle<int>?> findTemplateRect(String templateId) async => null;

  /// Returns whether a template's visual state is bright/enabled.
  Future<bool> isTemplateBright(String templateId) async => false;

  /// Reads text using OCR from the current screen.
  Future<String> readText() async => '';

  /// Finds a named icon on the current screen.
  Future<bool> findIcon(String iconId) async => findTemplate(iconId);

  /// Finds a named button on the current screen.
  Future<bool> findButton(String buttonId) async => findTemplate(buttonId);
}
