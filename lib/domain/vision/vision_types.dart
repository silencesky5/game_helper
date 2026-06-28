import 'dart:typed_data';

import '../screenshot/device_screenshot.dart';
import 'game_state.dart';

/// Multi-device image buffer that tracks current and previous screenshots.
class ImageBuffer {
  const ImageBuffer({required this.deviceId, required this.current, this.previous});

  final String deviceId;
  final DeviceScreenshot current;
  final DeviceScreenshot? previous;
  DateTime get timestamp => current.updatedAt;
}

/// Decoded screenshot pixels used internally by detectors.
class DecodedImageBuffer {
  const DecodedImageBuffer({required this.imageBuffer, required this.width, required this.height, required this.rgbaBytes});

  final ImageBuffer imageBuffer;
  final int width;
  final int height;
  final Uint8List rgbaBytes;

  int offset(int x, int y) => ((y * width) + x) * 4;
}

/// Bounds for a detected template.
class VisionBounds {
  const VisionBounds({required this.x, required this.y, required this.width, required this.height});

  final int x;
  final int y;
  final int width;
  final int height;
}

/// Point for a detection center.
class VisionPoint {
  const VisionPoint(this.x, this.y);

  final int x;
  final int y;
}

/// Result returned by template matching.
class TemplateMatchResult {
  const TemplateMatchResult({required this.templateName, required this.found, required this.confidence, this.center, this.bounds});

  final String templateName;
  final bool found;
  final double confidence;
  final VisionPoint? center;
  final VisionBounds? bounds;
}

/// Result returned by color detection.
class ColorResult {
  const ColorResult({required this.label, required this.detected, required this.rgb, required this.sampleCount, required this.confidence});

  final String label;
  final bool detected;
  final int rgb;
  final int sampleCount;
  final double confidence;
}

/// Aggregated result consumed by workflows and the desktop console.
class VisionResult {
  const VisionResult({
    required this.deviceId,
    required this.currentState,
    required this.matchedTemplates,
    required this.colorResults,
    required this.timestamp,
    required this.analysisTime,
  });

  final String deviceId;
  final GameState currentState;
  final List<TemplateMatchResult> matchedTemplates;
  final List<ColorResult> colorResults;
  final DateTime timestamp;
  final Duration analysisTime;

  int get matchCount => matchedTemplates.where((match) => match.found).length;
  String get detectionStatus => colorResults.any((result) => result.detected) || matchCount > 0 ? 'detected' : 'scanned';
}
