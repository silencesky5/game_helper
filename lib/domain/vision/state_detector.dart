import 'game_state.dart';
import 'vision_types.dart';

/// Foundation for generic state recognition from vision signals.
class StateDetector {
  const StateDetector();

  GameState detectState(DecodedImageBuffer image, List<TemplateMatchResult> matches, List<ColorResult> colors) {
    if (image.imageBuffer.current.pngBytes.isEmpty) return GameState.disconnected;
    if (matches.any((match) => match.found && match.templateName.toLowerCase().contains('loading'))) return GameState.loading;
    if (matches.any((match) => match.found && match.templateName.toLowerCase().contains('menu'))) return GameState.mainMenu;
    if (colors.any((color) => color.detected && color.confidence > 0.75)) return GameState.popup;
    return GameState.unknown;
  }
}
