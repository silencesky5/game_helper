import 'perception_config.dart';
import 'perception_types.dart';

class ChallengeDetector {
  const ChallengeDetector();

  ChallengeStatus detect(OCRResult ocr, PopupDetection popup, PerceptionConfig config) {
    final text = ocr.blocks.map((block) => block.text.toLowerCase()).join(' ');
    final types = <ChallengeType>[];
    if (popup.type == PopupType.verification || text.contains('verify')) types.add(ChallengeType.verificationScreen);
    if (RegExp(r'\d+\s*[+\-x*/]\s*\d+').hasMatch(text)) types.add(ChallengeType.mathProblem);
    if (text.contains('click') && text.contains('verify')) types.add(ChallengeType.clickVerification);
    if (text.contains('captcha') || text.contains('robot')) types.add(ChallengeType.captcha);
    final confidence = types.isEmpty ? 0.0 : 0.8;
    return ChallengeStatus(detected: confidence >= config.challengeThreshold, types: types, confidence: confidence);
  }
}
