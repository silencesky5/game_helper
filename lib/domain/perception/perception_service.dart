import '../logger/logger.dart';
import '../logger/logger_service.dart';
import '../screenshot/screenshot_repository.dart';
import '../vision/image_decoder.dart';
import '../vision/vision_repository.dart';
import '../vision/vision_service.dart';
import '../vision/vision_types.dart';
import 'challenge_detector.dart';
import 'ocr_service.dart';
import 'perception_config.dart';
import 'perception_repository.dart';
import 'perception_types.dart';
import 'popup_detector.dart';
import 'ui_detector.dart';

class PerceptionService {
  const PerceptionService({
    required this.visionService,
    required this.visionRepository,
    required this.screenshotRepository,
    required this.perceptionRepository,
    required this.config,
    this.logger,
    this.imageDecoder = const ImageDecoder(),
    this.ocrService = const NoOpOCRService(),
    this.popupDetector = const PopupDetector(),
    this.uiDetector = const UIDetector(),
    this.challengeDetector = const ChallengeDetector(),
    this.extraPopupDetectors = const <PopupDetector>[],
    this.extraUiDetectors = const <UIDetector>[],
    this.extraChallengeDetectors = const <ChallengeDetector>[],
  });

  final VisionService visionService;
  final VisionRepository visionRepository;
  final ScreenshotRepository screenshotRepository;
  final PerceptionRepository perceptionRepository;
  final PerceptionConfig config;
  final LoggerService? logger;
  final ImageDecoder imageDecoder;
  final OCRService ocrService;
  final PopupDetector popupDetector;
  final UIDetector uiDetector;
  final ChallengeDetector challengeDetector;
  final List<PopupDetector> extraPopupDetectors;
  final List<UIDetector> extraUiDetectors;
  final List<ChallengeDetector> extraChallengeDetectors;

  Future<PerceptionResult?> analyze(String deviceId) async {
    final cached = perceptionRepository.lastResult(deviceId);
    if (cached != null && DateTime.now().difference(cached.timestamp) < config.cacheTime) return cached;
    final vision = await visionService.analyze(deviceId);
    final screenshot = screenshotRepository.latest(deviceId);
    if (vision == null || screenshot == null) return cached;
    final stopwatch = Stopwatch()..start();
    final image = await imageDecoder.decode(ImageBuffer(deviceId: deviceId, current: screenshot, previous: screenshotRepository.previous(deviceId)));
    return _analyzeDecoded(vision, image, stopwatch);
  }

  Future<PerceptionResult> analyzeImage(VisionResult vision, DecodedImageBuffer image) async => _analyzeDecoded(vision, image, Stopwatch()..start());

  Future<PerceptionResult> _analyzeDecoded(VisionResult vision, DecodedImageBuffer image, Stopwatch stopwatch) async {
    final ocr = await recognizeText(image);
    logger?.log(LogLevel.info, '[PERCEPTION] OCR Completed count=${ocr.count}');
    final uiTree = detectUI(image, ocr);
    logger?.log(LogLevel.info, '[PERCEPTION] UI Parsed elements=${uiTree.elementCount}');
    final popup = detectPopup(ocr, uiTree);
    logger?.log(LogLevel.info, '[PERCEPTION] Popup Detected type=${popup.type.name}');
    final challenge = detectChallenge(ocr, popup);
    logger?.log(LogLevel.info, '[PERCEPTION] Challenge Detected status=${challenge.label}');
    stopwatch.stop();
    final result = PerceptionResult(deviceId: vision.deviceId, currentState: vision.currentState, popup: popup, ocr: ocr, uiTree: uiTree, challengeStatus: challenge, timestamp: DateTime.now(), analysisTime: stopwatch.elapsed);
    perceptionRepository.save(result);
    logger?.log(LogLevel.info, '[PERCEPTION] Semantic Updated device=${vision.deviceId} time=${stopwatch.elapsedMilliseconds}ms');
    return result;
  }

  PopupDetection detectPopup(OCRResult ocr, UIElement uiTree) {
    final detections = <PopupDetection>[popupDetector.detect(ocr, uiTree, config)];
    for (final detector in extraPopupDetectors) {
      detections.add(detector.detect(ocr, uiTree, config));
    }
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections.first;
  }

  UIElement detectUI(DecodedImageBuffer image, OCRResult ocr) {
    if (extraUiDetectors.isNotEmpty) return extraUiDetectors.first.detect(image, ocr, config);
    return uiDetector.detect(image, ocr, config);
  }
  Future<OCRResult> recognizeText(DecodedImageBuffer image) => config.ocrEnabled ? ocrService.recognizeText(image) : Future<OCRResult>.value(OCRResult(blocks: const <TextBlock>[], timestamp: DateTime.now()));
  ChallengeStatus detectChallenge(OCRResult ocr, PopupDetection popup) {
    final detections = <ChallengeStatus>[challengeDetector.detect(ocr, popup, config)];
    for (final detector in extraChallengeDetectors) {
      detections.add(detector.detect(ocr, popup, config));
    }
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections.first;
  }
}
