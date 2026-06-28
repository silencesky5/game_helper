class PerceptionConfig {
  const PerceptionConfig({
    this.ocrEnabled = true,
    this.ocrRefreshInterval = const Duration(seconds: 1),
    this.popupThreshold = 0.70,
    this.uiDetectionThreshold = 0.60,
    this.challengeThreshold = 0.70,
    this.cacheTime = const Duration(milliseconds: 500),
  });

  factory PerceptionConfig.fromJson(Map<String, Object?> json) => PerceptionConfig(
        ocrEnabled: json['ocrEnabled'] as bool? ?? true,
        ocrRefreshInterval: Duration(milliseconds: (json['ocrRefreshIntervalMs'] as num?)?.toInt() ?? 1000),
        popupThreshold: (json['popupThreshold'] as num?)?.toDouble() ?? 0.70,
        uiDetectionThreshold: (json['uiDetectionThreshold'] as num?)?.toDouble() ?? 0.60,
        challengeThreshold: (json['challengeThreshold'] as num?)?.toDouble() ?? 0.70,
        cacheTime: Duration(milliseconds: (json['cacheTimeMs'] as num?)?.toInt() ?? 500),
      );

  final bool ocrEnabled;
  final Duration ocrRefreshInterval;
  final double popupThreshold;
  final double uiDetectionThreshold;
  final double challengeThreshold;
  final Duration cacheTime;
}
