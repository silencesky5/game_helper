/// Runtime configuration for the generic Vision Layer.
class VisionConfig {
  const VisionConfig({
    this.matchingThreshold = 0.85,
    this.refreshInterval = const Duration(seconds: 1),
    this.cacheTime = const Duration(milliseconds: 500),
    this.detectionArea = const DetectionArea(),
  });

  factory VisionConfig.fromJson(Map<String, Object?> json) {
    final area = json['detectionArea'];
    return VisionConfig(
      matchingThreshold: (json['matchingThreshold'] as num?)?.toDouble() ?? 0.85,
      refreshInterval: Duration(milliseconds: (json['refreshIntervalMs'] as num?)?.toInt() ?? 1000),
      cacheTime: Duration(milliseconds: (json['cacheTimeMs'] as num?)?.toInt() ?? 500),
      detectionArea: area is Map<String, Object?> ? DetectionArea.fromJson(area) : const DetectionArea(),
    );
  }

  final double matchingThreshold;
  final Duration refreshInterval;
  final Duration cacheTime;
  final DetectionArea detectionArea;
}

/// Optional rectangular area used to restrict analysis.
class DetectionArea {
  const DetectionArea({this.x = 0, this.y = 0, this.width = 0, this.height = 0});

  factory DetectionArea.fromJson(Map<String, Object?> json) => DetectionArea(
        x: (json['x'] as num?)?.toInt() ?? 0,
        y: (json['y'] as num?)?.toInt() ?? 0,
        width: (json['width'] as num?)?.toInt() ?? 0,
        height: (json['height'] as num?)?.toInt() ?? 0,
      );

  final int x;
  final int y;
  final int width;
  final int height;

  bool get isEnabled => width > 0 && height > 0;
}
