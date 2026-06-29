import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';
import '../../domain/screenshot/device_screenshot.dart';
import '../../domain/screenshot/screenshot_repository.dart';
import '../../domain/vision/image_decoder.dart';
import '../../domain/vision/template_matcher.dart';
import '../../domain/vision/vision_types.dart';

/// Scenes supported by the minimum fixed-UI vision system.
enum Scene {
  /// Android launcher desktop where the GrowStone icon is visible.
  android,

  /// GrowStone loading screen. Automation must not act in this scene.
  loading,

  /// Daily attendance popup.
  attendance,

  /// Main GrowStone home scene.
  home,

  /// Bag window.
  bag,

  /// Mail window.
  mail,

  /// Shop window.
  shop,

  /// No known fixed UI matched.
  unknown,
}

/// Stable template identifiers used by all vision detectors.
abstract final class VisionTemplates {
  static const androidGrowstoneIcon = 'android/growstone_icon';
  static const loadingLogo = 'loading/loading_logo';
  static const attendanceTitle = 'attendance/attendance_title';
  static const attendanceReceiveAll = 'attendance/receive_all';
  static const attendanceReceiveAllDisabled = 'attendance/receive_all_disabled';
  static const attendanceCloseButton = 'attendance/close_button';
  static const homeBag = 'home/bag';
  static const homeShop = 'home/shop';
  static const homeMail = 'home/mail';
  static const homeCraft = 'home/craft';
  static const bagTitle = 'bag/title';
  static const mailTitle = 'mail/title';
  static const shopTitle = 'shop/title';

  /// Converts a stable template id like `home/bag` into its asset path.
  static String assetPath(String templateId) => 'assets/templates/$templateId.png';
}

/// Classification for failed vision operations.
enum VisionFailure { templateNotFound, visionUnavailable }

/// Single ImageDetector lookup result that callers can reuse without matching twice.
class VisionDetectionResult {
  const VisionDetectionResult({
    required this.templateId,
    required this.found,
    required this.confidence,
    this.rect,
    this.failure,
  });

  final String templateId;
  final bool found;
  final double confidence;
  final Rectangle<int>? rect;
  final VisionFailure? failure;
}

/// Central image-recognition facade for OpenCV, OCR, and template matching.
class ImageDetector {
  /// Creates an image detector backed by the latest cached ADB screenshot.
  const ImageDetector({
    this.screenshotRepository,
    this.deviceId,
    this.logger,
    this.imageDecoder = const ImageDecoder(),
    this.templateMatcher = const TemplateMatcher(),
    this.thresholds = const <String, double>{},
    this.refreshScreenshot,
  });

  final ScreenshotRepository? screenshotRepository;
  final String? deviceId;
  final LoggerService? logger;
  final ImageDecoder imageDecoder;
  final TemplateMatcher templateMatcher;
  final Map<String, double> thresholds;
  final Future<void> Function()? refreshScreenshot;

  static final Map<String, TemplateAsset?> _templateCache = <String, TemplateAsset?>{};
  static final Map<String, VisionDetectionResult> _lastDetections = <String, VisionDetectionResult>{};
  static DeviceScreenshot? _decodedScreenshot;
  static DecodedImageBuffer? _decodedImage;

  /// Most recent lookup for [templateId], if one has been performed.
  VisionDetectionResult? lastDetection(String templateId) => _lastDetections[templateId];

  /// Finds a named UI template on the current emulator screen.
  Future<bool> findTemplate(String templateId) async {
    final result = await findTemplateResult(templateId);
    return result.found;
  }

  /// Finds a template and returns the full result, including bounds and confidence.
  Future<VisionDetectionResult> findTemplateResult(String templateId) async {
    var screenshot = _latestScreenshot();
    final refresh = refreshScreenshot;
    final stale = screenshot == null || DateTime.now().difference(screenshot.updatedAt) > const Duration(milliseconds: 250);
    if (refresh != null && stale) {
      await refresh();
      screenshot = _latestScreenshot();
    }
    if (screenshot == null || screenshot.pngBytes.isEmpty) {
      final result = VisionDetectionResult(
        templateId: templateId,
        found: false,
        confidence: 0,
        failure: VisionFailure.visionUnavailable,
      );
      _lastDetections[templateId] = result;
      _log(LogLevel.warning, '[Vision]\nSearching\n$templateId\nResult\nVISION UNAVAILABLE');
      return result;
    }

    final template = await _loadTemplate(templateId);
    if (template == null) {
      final result = VisionDetectionResult(
        templateId: templateId,
        found: false,
        confidence: 0,
        failure: VisionFailure.templateNotFound,
      );
      _lastDetections[templateId] = result;
      _log(LogLevel.warning, '[Vision]\nSearching\n$templateId\nResult\nTEMPLATE NOT FOUND');
      return result;
    }

    final image = await _decodeLatest(screenshot);
    final threshold = _thresholdFor(templateId);
    final match = await templateMatcher.find(image, template, threshold: threshold);
    final bounds = match.bounds;
    final rect = bounds == null
        ? null
        : Rectangle<int>(bounds.x, bounds.y, bounds.width, bounds.height);
    final result = VisionDetectionResult(
      templateId: templateId,
      found: match.found,
      confidence: match.confidence,
      rect: rect,
    );
    _lastDetections[templateId] = result;
    _log(
      LogLevel.info,
      '[Vision]\nSearching\n$templateId\nConfidence\n${(match.confidence * 100).toStringAsFixed(0)}%\nResult\n${match.found ? 'FOUND' : 'NOT FOUND'}',
    );
    return result;
  }

  /// Finds the screen rectangle occupied by a named template.
  Future<Rectangle<int>?> findTemplateRect(String templateId) async {
    final cached = _lastDetections[templateId];
    if (cached != null && cached.found) return cached.rect;
    return (await findTemplateResult(templateId)).rect;
  }

  /// Returns whether a template's visual state is bright/enabled.
  Future<bool> isTemplateBright(String templateId) async {
    final rect = await findTemplateRect(templateId);
    final image = _decodedImage;
    if (rect == null || image == null) return false;
    var bright = 0;
    var sampled = 0;
    for (var y = rect.top; y < rect.bottom; y += 3) {
      for (var x = rect.left; x < rect.right; x += 3) {
        final offset = image.offset(x, y);
        final luminance = (image.rgbaBytes[offset] + image.rgbaBytes[offset + 1] + image.rgbaBytes[offset + 2]) ~/ 3;
        if (luminance >= 120) bright++;
        sampled++;
      }
    }
    return sampled > 0 && bright / sampled >= 0.35;
  }

  /// Reads text using OCR from the current screen.
  Future<String> readText() async => '';

  /// Finds a named icon on the current screen.
  Future<bool> findIcon(String iconId) async => findTemplate(iconId);

  /// Finds a named button on the current screen.
  Future<bool> findButton(String buttonId) async => findTemplate(buttonId);

  /// Detects the current scene using only fixed UI templates.
  Future<Scene> detectScene() => const VisionSystem().detectScene(this);

  /// Builds a dashboard-friendly scene debug report.
  Future<VisionDebugReport> debugScene() => const VisionSystem().debugScene(this);

  DeviceScreenshot? _latestScreenshot() {
    final repository = screenshotRepository;
    if (repository == null) return null;
    if (deviceId != null) return repository.latest(deviceId!);
    final screenshots = repository.all;
    return screenshots.isEmpty ? null : screenshots.last;
  }

  Future<DecodedImageBuffer> _decodeLatest(DeviceScreenshot screenshot) async {
    if (identical(_decodedScreenshot, screenshot) && _decodedImage != null) return _decodedImage!;
    _decodedScreenshot = screenshot;
    _decodedImage = await imageDecoder.decode(ImageBuffer(deviceId: screenshot.deviceId, current: screenshot));
    return _decodedImage!;
  }

  Future<TemplateAsset?> _loadTemplate(String templateId) async {
    if (_templateCache.containsKey(templateId)) return _templateCache[templateId];
    final path = VisionTemplates.assetPath(templateId);
    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final decoded = await imageDecoder.decode(
        ImageBuffer(
          deviceId: 'template:$templateId',
          current: DeviceScreenshot(deviceId: 'template:$templateId', pngBytes: bytes, updatedAt: DateTime.now()),
        ),
      );
      final asset = TemplateAsset(
        name: templateId,
        width: decoded.width,
        height: decoded.height,
        rgbaBytes: Uint8List.fromList(decoded.rgbaBytes),
      );
      _templateCache[templateId] = asset;
      return asset;
    } on FlutterError catch (error) {
      _templateCache[templateId] = null;
      _log(LogLevel.warning, '[Vision] Missing template $path: ${error.message}');
      return null;
    }
  }

  double _thresholdFor(String templateId) {
    if (thresholds.containsKey(templateId)) return thresholds[templateId]!;
    if (templateId == VisionTemplates.loadingLogo) return 0.85;
    if (templateId.contains('button') || templateId.contains('receive')) return 0.92;
    if (templateId.contains('icon') || templateId.startsWith('home/')) return 0.95;
    return 0.90;
  }

  void _log(LogLevel level, String message) => logger?.log(level, message);
}

/// Boolean detector contract for a single fixed-UI scene.
abstract class SceneDetector {
  /// Creates a detector for [scene].
  const SceneDetector(this.scene);

  /// Scene returned when [detect] succeeds.
  final Scene scene;

  /// Returns true when this scene's fixed UI is present.
  Future<bool> detect(ImageDetector detector);
}

class AndroidDetector extends SceneDetector {
  const AndroidDetector() : super(Scene.android);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findIcon(VisionTemplates.androidGrowstoneIcon);
}

class LoadingDetector extends SceneDetector {
  const LoadingDetector() : super(Scene.loading);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.loadingLogo);
}

class AttendanceDetector extends SceneDetector {
  const AttendanceDetector() : super(Scene.attendance);

  @override
  Future<bool> detect(ImageDetector detector) async {
    final hasTitle = await detector.findTemplate(
      VisionTemplates.attendanceTitle,
    );
    final hasReceiveAll = await detector.findTemplate(
      VisionTemplates.attendanceReceiveAll,
    );
    final hasClose = await detector.findTemplate(
      VisionTemplates.attendanceCloseButton,
    );
    return hasTitle && hasReceiveAll && hasClose;
  }
}

class HomeDetector extends SceneDetector {
  const HomeDetector() : super(Scene.home);

  @override
  Future<bool> detect(ImageDetector detector) async {
    final hasBag = await detector.findTemplate(VisionTemplates.homeBag);
    final hasShop = await detector.findTemplate(VisionTemplates.homeShop);
    final hasMail = await detector.findTemplate(VisionTemplates.homeMail);
    final hasCraft = await detector.findTemplate(VisionTemplates.homeCraft);
    return hasBag && hasShop && hasMail && hasCraft;
  }
}

class BagDetector extends SceneDetector {
  const BagDetector() : super(Scene.bag);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.bagTitle);
}

class MailDetector extends SceneDetector {
  const MailDetector() : super(Scene.mail);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.mailTitle);
}

class ShopDetector extends SceneDetector {
  const ShopDetector() : super(Scene.shop);

  @override
  Future<bool> detect(ImageDetector detector) =>
      detector.findTemplate(VisionTemplates.shopTitle);
}

/// Minimum Vision Set scene resolver.
class VisionSystem {
  /// Creates a vision system with fixed detector precedence.
  const VisionSystem({
    this.detectors = const <SceneDetector>[
      AttendanceDetector(),
      LoadingDetector(),
      HomeDetector(),
      BagDetector(),
      MailDetector(),
      ShopDetector(),
      AndroidDetector(),
    ],
  });

  /// Ordered detectors. Popup scenes run first so automation can preempt tasks.
  final List<SceneDetector> detectors;

  /// Returns the first matching scene, or [Scene.unknown].
  Future<Scene> detectScene(ImageDetector detector) async {
    for (final sceneDetector in detectors) {
      if (await sceneDetector.detect(detector)) {
        return sceneDetector.scene;
      }
    }
    return Scene.unknown;
  }

  /// Returns scene plus the Home template details requested by the dashboard.
  Future<VisionDebugReport> debugScene(ImageDetector detector) async {
    final scene = await detectScene(detector);
    final probes = <VisionDebugProbe>[];
    for (final entry in <String, String>{
      'Bag': VisionTemplates.homeBag,
      'Shop': VisionTemplates.homeShop,
      'Mail': VisionTemplates.homeMail,
      'Craft': VisionTemplates.homeCraft,
    }.entries) {
      final matched = await detector.findTemplate(entry.value);
      probes.add(VisionDebugProbe(name: entry.key, matched: matched));
    }
    return VisionDebugReport(scene: scene, probes: probes);
  }
}

/// One template probe shown by the dashboard vision debugger.
class VisionDebugProbe {
  /// Creates a debug probe result.
  const VisionDebugProbe({
    required this.name,
    required this.matched,
    this.score,
  });

  /// Human-readable template name.
  final String name;

  /// Whether the template matched.
  final bool matched;

  /// Optional confidence score when provided by a detector implementation.
  final double? score;
}

/// Dashboard-friendly scene detection report.
class VisionDebugReport {
  /// Creates a scene debug report.
  const VisionDebugReport({required this.scene, required this.probes});

  /// Current detected scene.
  final Scene scene;

  /// Template probe details.
  final List<VisionDebugProbe> probes;

  @override
  String toString() {
    final buffer = StringBuffer('Current Scene: ${scene.name}');
    for (final probe in probes) {
      buffer
        ..writeln()
        ..writeln('--------------')
        ..writeln(probe.name)
        ..writeln(probe.matched ? '✔' : '✘')
        ..write(
          probe.score?.toStringAsFixed(2) ??
              (probe.matched ? '1.00' : '0.00'),
        );
    }
    return buffer.toString();
  }
}
