import '../vision/game_state.dart';
import '../vision/vision_types.dart';

enum PopupType { none, dialog, reward, error, login, maintenance, verification, announcement }

enum UIElementType { window, button, label, image, icon, checkbox, progressBar }

enum ChallengeType { verificationScreen, mathProblem, clickVerification, captcha }

class TextBlock {
  const TextBlock({required this.text, required this.boundingBox, required this.confidence});

  final String text;
  final VisionBounds boundingBox;
  final double confidence;
}

class OCRResult {
  const OCRResult({required this.blocks, required this.timestamp});

  final List<TextBlock> blocks;
  final DateTime timestamp;

  int get count => blocks.length;
  String get preview => blocks.map((block) => block.text).take(5).join(' · ');
}

class UIElement {
  const UIElement({required this.type, required this.label, required this.bounds, this.confidence = 1, this.children = const <UIElement>[]});

  final UIElementType type;
  final String label;
  final VisionBounds bounds;
  final double confidence;
  final List<UIElement> children;

  int get elementCount => 1 + children.fold<int>(0, (total, child) => total + child.elementCount);
}

class PopupDetection {
  const PopupDetection({required this.type, required this.confidence, this.message = ''});

  final PopupType type;
  final double confidence;
  final String message;

  bool get detected => type != PopupType.none;
}

class ChallengeStatus {
  const ChallengeStatus({required this.detected, required this.types, required this.confidence});

  final bool detected;
  final List<ChallengeType> types;
  final double confidence;

  String get label => detected ? types.map((type) => type.name).join(', ') : 'none';
}

class PerceptionResult {
  const PerceptionResult({
    required this.deviceId,
    required this.currentState,
    required this.popup,
    required this.ocr,
    required this.uiTree,
    required this.challengeStatus,
    required this.timestamp,
    required this.analysisTime,
  });

  final String deviceId;
  final GameState currentState;
  final PopupDetection popup;
  final OCRResult ocr;
  final UIElement uiTree;
  final ChallengeStatus challengeStatus;
  final DateTime timestamp;
  final Duration analysisTime;

  int get uiElementCount => uiTree.elementCount;
}
