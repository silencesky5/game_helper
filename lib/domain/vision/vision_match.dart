import 'dart:ui';

/// Minimal template-match result for dashboard GrowStone validation.
class VisionMatch {
  const VisionMatch({
    required this.found,
    required this.confidence,
    required this.rect,
  });

  final bool found;
  final double confidence;
  final Rect? rect;
}
