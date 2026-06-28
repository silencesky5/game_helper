import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../logger/logger.dart';
import '../logger/logger_service.dart';
import '../screenshot/device_screenshot.dart';
import '../screenshot/screenshot_repository.dart';
import 'color_detector.dart';
import 'game_state.dart';
import 'image_decoder.dart';
import 'state_detector.dart';
import 'template_matcher.dart';
import 'vision_config.dart';
import 'vision_match.dart';
import 'vision_repository.dart';
import 'vision_types.dart';

/// Shared platform vision service used by workflows and plugins.
class VisionService {
  const VisionService({
    required this.screenshotRepository,
    required this.visionRepository,
    required this.config,
    this.logger,
    this.imageDecoder = const ImageDecoder(),
    this.templateMatcher = const TemplateMatcher(),
    this.colorDetector = const ColorDetector(),
    this.stateDetector = const StateDetector(),
    this.templates = const <TemplateAsset>[],
  });

  final ScreenshotRepository screenshotRepository;
  final VisionRepository visionRepository;
  final VisionConfig config;
  final LoggerService? logger;
  final ImageDecoder imageDecoder;
  final TemplateMatcher templateMatcher;
  final ColorDetector colorDetector;
  final StateDetector stateDetector;
  final List<TemplateAsset> templates;

  /// Runs screenshot decoding, template matching, color detection, state detection, and caching.
  Future<VisionResult?> analyze(String deviceId) async {
    final cached = visionRepository.lastAnalysis(deviceId);
    final screenshot = screenshotRepository.latest(deviceId);
    if (screenshot == null) return cached;
    if (cached != null && DateTime.now().difference(cached.timestamp) < config.cacheTime) return cached;

    final stopwatch = Stopwatch()..start();
    final buffer = ImageBuffer(deviceId: deviceId, current: screenshot, previous: screenshotRepository.previous(deviceId));
    final image = await imageDecoder.decode(buffer);
    final matches = <TemplateMatchResult>[];
    for (final template in templates) {
      final match = await findTemplate(image, template);
      matches.add(match);
      logger?.log(LogLevel.info, '[VISION] Template ${match.found ? 'Found' : 'Missing'} ${template.name} confidence=${match.confidence.toStringAsFixed(2)}');
    }
    final colors = <ColorResult>[detectColor(image, 0xffffff, label: 'bright-pixels')];
    final state = detectState(image, matches, colors);
    stopwatch.stop();
    final result = VisionResult(
      deviceId: deviceId,
      currentState: state,
      matchedTemplates: matches,
      colorResults: colors,
      timestamp: DateTime.now(),
      analysisTime: stopwatch.elapsed,
    );
    final previousState = visionRepository.lastState(deviceId);
    visionRepository.save(result);
    if (previousState != state) logger?.log(LogLevel.info, '[VISION] State Changed ${previousState.name} -> ${state.name}');
    logger?.log(LogLevel.info, '[VISION] Analysis Time ${stopwatch.elapsedMilliseconds}ms for $deviceId');
    return result;
  }


  /// Finds the GrowStone launcher icon in a captured ADB screenshot.
  Future<VisionMatch> findGrowStone(DeviceScreenshot screenshot) async {
    const assetPath = 'assets/vision/android/growstone_icon.png';
    try {
      final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
      final image = await imageDecoder.decode(ImageBuffer(deviceId: screenshot.deviceId, current: screenshot));
      final templateImage = await imageDecoder.decode(
        ImageBuffer(
          deviceId: 'growstone-template',
          current: DeviceScreenshot(deviceId: 'growstone-template', pngBytes: bytes, updatedAt: DateTime.now()),
        ),
      );
      final match = await templateMatcher.find(
        image,
        TemplateAsset(name: 'GrowStone', width: templateImage.width, height: templateImage.height, rgbaBytes: templateImage.rgbaBytes),
        threshold: config.matchingThreshold,
      );
      final bounds = match.bounds;
      final rect = bounds == null
          ? null
          : Rect.fromLTWH(
              bounds.x.toDouble(),
              bounds.y.toDouble(),
              bounds.width.toDouble(),
              bounds.height.toDouble(),
            );
      return VisionMatch(found: match.found, confidence: match.confidence, rect: rect);
    } on FlutterError catch (error) {
      logger?.log(LogLevel.error, '[VISION] GrowStone template unavailable: ${error.message}');
      return const VisionMatch(found: false, confidence: 0, rect: null);
    }
  }

  Future<TemplateMatchResult> findTemplate(DecodedImageBuffer image, TemplateAsset template) {
    return templateMatcher.find(image, template, threshold: config.matchingThreshold);
  }

  ColorResult detectColor(DecodedImageBuffer image, int rgb, {String label = 'configured-color'}) {
    final result = colorDetector.detectColor(image, rgb, label: label, area: config.detectionArea);
    if (result.detected) logger?.log(LogLevel.info, '[VISION] Color Detected $label confidence=${result.confidence.toStringAsFixed(2)}');
    return result;
  }

  GameState detectState(DecodedImageBuffer image, List<TemplateMatchResult> matches, List<ColorResult> colors) {
    return stateDetector.detectState(image, matches, colors);
  }
}
