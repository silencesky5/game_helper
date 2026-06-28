import 'vision_config.dart';
import 'vision_types.dart';

/// Generic color analysis utilities for screenshots.
class ColorDetector {
  const ColorDetector({this.tolerance = 24});

  final int tolerance;

  ColorResult detectColor(DecodedImageBuffer image, int targetRgb, {String label = 'configured-color', DetectionArea area = const DetectionArea()}) {
    final sample = _area(area, image);
    var matches = 0;
    for (var y = sample.y; y < sample.y + sample.height; y++) {
      for (var x = sample.x; x < sample.x + sample.width; x++) {
        if (_matches(image, x, y, targetRgb)) matches++;
      }
    }
    final total = sample.width * sample.height;
    return ColorResult(label: label, detected: matches > 0, rgb: targetRgb, sampleCount: total, confidence: total == 0 ? 0 : matches / total);
  }

  ColorResult areaAverage(DecodedImageBuffer image, {String label = 'area-average', DetectionArea area = const DetectionArea()}) {
    final sample = _area(area, image);
    var r = 0;
    var g = 0;
    var b = 0;
    final total = sample.width * sample.height;
    for (var y = sample.y; y < sample.y + sample.height; y++) {
      for (var x = sample.x; x < sample.x + sample.width; x++) {
        final offset = image.offset(x, y);
        r += image.rgbaBytes[offset];
        g += image.rgbaBytes[offset + 1];
        b += image.rgbaBytes[offset + 2];
      }
    }
    final rgb = total == 0 ? 0 : ((r ~/ total) << 16) | ((g ~/ total) << 8) | (b ~/ total);
    return ColorResult(label: label, detected: total > 0, rgb: rgb, sampleCount: total, confidence: total > 0 ? 1 : 0);
  }

  bool compareRgb(int actualRgb, int targetRgb) {
    final dr = ((actualRgb >> 16) & 0xff) - ((targetRgb >> 16) & 0xff);
    final dg = ((actualRgb >> 8) & 0xff) - ((targetRgb >> 8) & 0xff);
    final db = (actualRgb & 0xff) - (targetRgb & 0xff);
    return dr.abs() <= tolerance && dg.abs() <= tolerance && db.abs() <= tolerance;
  }

  bool _matches(DecodedImageBuffer image, int x, int y, int targetRgb) {
    final offset = image.offset(x, y);
    final rgb = (image.rgbaBytes[offset] << 16) | (image.rgbaBytes[offset + 1] << 8) | image.rgbaBytes[offset + 2];
    return compareRgb(rgb, targetRgb);
  }

  DetectionArea _area(DetectionArea area, DecodedImageBuffer image) {
    if (!area.isEnabled) return DetectionArea(width: image.width, height: image.height);
    return DetectionArea(
      x: area.x.clamp(0, image.width - 1).toInt(),
      y: area.y.clamp(0, image.height - 1).toInt(),
      width: area.width.clamp(1, image.width).toInt(),
      height: area.height.clamp(1, image.height).toInt(),
    );
  }
}
