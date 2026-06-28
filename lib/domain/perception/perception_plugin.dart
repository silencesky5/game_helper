import '../vision/state_detector.dart';
import 'challenge_detector.dart';
import 'popup_detector.dart';
import 'ui_detector.dart';

abstract class PerceptionPlugin {
  Iterable<PopupDetector> get popupDetectors => const <PopupDetector>[];
  Iterable<UIDetector> get uiDetectors => const <UIDetector>[];
  Iterable<StateDetector> get stateDetectors => const <StateDetector>[];
  Iterable<ChallengeDetector> get challengeDetectors => const <ChallengeDetector>[];
}
