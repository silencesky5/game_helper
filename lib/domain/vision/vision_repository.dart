import 'game_state.dart';
import 'vision_types.dart';

/// In-memory cache for Vision Layer results per device.
class VisionRepository {
  final Map<String, VisionResult> _lastAnalysis = <String, VisionResult>{};
  final Map<String, TemplateMatchResult> _lastMatch = <String, TemplateMatchResult>{};
  final Map<String, GameState> _lastState = <String, GameState>{};

  VisionResult? lastAnalysis(String deviceId) => _lastAnalysis[deviceId];
  TemplateMatchResult? lastMatch(String deviceId) => _lastMatch[deviceId];
  GameState lastState(String deviceId) => _lastState[deviceId] ?? GameState.unknown;
  List<VisionResult> get all => List<VisionResult>.unmodifiable(_lastAnalysis.values);

  void save(VisionResult result) {
    _lastAnalysis[result.deviceId] = result;
    _lastState[result.deviceId] = result.currentState;
    final matches = result.matchedTemplates.where((match) => match.found);
    if (matches.isNotEmpty) _lastMatch[result.deviceId] = matches.first;
  }
}
