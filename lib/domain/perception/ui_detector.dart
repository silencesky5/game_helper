import '../vision/vision_types.dart';
import 'perception_config.dart';
import 'perception_types.dart';

class UIDetector {
  const UIDetector();

  UIElement detect(DecodedImageBuffer image, OCRResult ocr, PerceptionConfig config) {
    final children = <UIElement>[];
    for (final block in ocr.blocks) {
      children.add(UIElement(type: UIElementType.label, label: block.text, bounds: block.boundingBox, confidence: block.confidence));
    }
    if (children.isEmpty && image.width > 0 && image.height > 0 && config.uiDetectionThreshold <= 1) {
      children.add(UIElement(type: UIElementType.image, label: 'screenshot-content', bounds: VisionBounds(x: 0, y: 0, width: image.width, height: image.height), confidence: config.uiDetectionThreshold));
    }
    return UIElement(type: UIElementType.window, label: 'Root Window', bounds: VisionBounds(x: 0, y: 0, width: image.width, height: image.height), children: children);
  }
}
