import 'perception_config.dart';
import 'perception_types.dart';

class PopupDetector {
  const PopupDetector();

  PopupDetection detect(OCRResult ocr, UIElement uiTree, PerceptionConfig config) {
    final text = ocr.blocks.map((block) => block.text.toLowerCase()).join(' ');
    PopupType type = PopupType.none;
    if (_containsAny(text, const <String>['verify', 'verification', 'captcha'])) type = PopupType.verification;
    if (_containsAny(text, const <String>['maintenance', 'server down'])) type = PopupType.maintenance;
    if (_containsAny(text, const <String>['login', 'sign in'])) type = PopupType.login;
    if (_containsAny(text, const <String>['error', 'failed'])) type = PopupType.error;
    if (_containsAny(text, const <String>['reward', 'claim'])) type = PopupType.reward;
    if (_containsAny(text, const <String>['announcement', 'notice'])) type = PopupType.announcement;
    if (type == PopupType.none && uiTree.children.length >= 2) type = PopupType.dialog;
    final confidence = type == PopupType.none ? 0.0 : 0.75;
    return confidence >= config.popupThreshold ? PopupDetection(type: type, confidence: confidence) : const PopupDetection(type: PopupType.none, confidence: 0);
  }

  bool _containsAny(String value, List<String> needles) => needles.any(value.contains);
}
