import 'dart:typed_data';

import 'vision_types.dart';

/// Generic template matching contract. Templates are supplied as assets/bytes,
/// never hard-coded in detector logic.
class TemplateMatcher {
  const TemplateMatcher();

  Future<TemplateMatchResult> find(DecodedImageBuffer screenshot, TemplateAsset template, {required double threshold}) async {
    if (template.rgbaBytes.isEmpty || template.width <= 0 || template.height <= 0) {
      return TemplateMatchResult(templateName: template.name, found: false, confidence: 0);
    }
    if (template.width > screenshot.width || template.height > screenshot.height) {
      return TemplateMatchResult(templateName: template.name, found: false, confidence: 0);
    }

    var bestConfidence = 0.0;
    var bestX = 0;
    var bestY = 0;
    for (var y = 0; y <= screenshot.height - template.height; y += 4) {
      for (var x = 0; x <= screenshot.width - template.width; x += 4) {
        final confidence = _confidenceAt(screenshot, template, x, y);
        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestX = x;
          bestY = y;
        }
      }
    }
    final found = bestConfidence >= threshold;
    return TemplateMatchResult(
      templateName: template.name,
      found: found,
      confidence: bestConfidence,
      center: found ? VisionPoint(bestX + template.width ~/ 2, bestY + template.height ~/ 2) : null,
      bounds: found ? VisionBounds(x: bestX, y: bestY, width: template.width, height: template.height) : null,
    );
  }

  double _confidenceAt(DecodedImageBuffer screenshot, TemplateAsset template, int startX, int startY) {
    var compared = 0;
    var matched = 0;
    for (var y = 0; y < template.height; y += 2) {
      for (var x = 0; x < template.width; x += 2) {
        final screenshotOffset = screenshot.offset(startX + x, startY + y);
        final templateOffset = ((y * template.width) + x) * 4;
        final distance = (screenshot.rgbaBytes[screenshotOffset] - template.rgbaBytes[templateOffset]).abs() +
            (screenshot.rgbaBytes[screenshotOffset + 1] - template.rgbaBytes[templateOffset + 1]).abs() +
            (screenshot.rgbaBytes[screenshotOffset + 2] - template.rgbaBytes[templateOffset + 2]).abs();
        if (distance <= 36) matched++;
        compared++;
      }
    }
    return compared == 0 ? 0 : matched / compared;
  }
}

/// Decoded template asset passed into [TemplateMatcher].
class TemplateAsset {
  const TemplateAsset({required this.name, required this.width, required this.height, required this.rgbaBytes});

  final String name;
  final int width;
  final int height;
  final Uint8List rgbaBytes;
}
