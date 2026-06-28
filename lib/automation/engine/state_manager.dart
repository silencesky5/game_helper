import '../models/game_state.dart';
import 'image_detector.dart';

/// Single source of truth for game state detection.
class StateManager {
  /// Creates a state manager.
  StateManager({
    this.imageDetector = const ImageDetector(),
    GameState initialState = const GameState(),
  }) : _state = initialState;

  final ImageDetector imageDetector;
  GameState _state;

  /// Latest shared game state.
  GameState get state => _state;

  /// Replaces state after detector services produce a new observation.
  void update(GameState state) => _state = state;

  Future<Scene> detectScene() => imageDetector.detectScene();

  Future<bool> hasGrowStoneIcon() =>
      imageDetector.findIcon(VisionTemplates.androidGrowstoneIcon);

  Future<bool> isLoadingScene() async =>
      await detectScene() == Scene.loading || _state.currentScene == 'loading';

  Future<bool> isHomeScene() async =>
      _state.currentScene == 'home' || await detectScene() == Scene.home;

  bool isLogin() => _state.currentScene == 'login';
  bool isMining() => _state.mining;
  bool isInventoryOpen() => _state.currentScene == 'inventory';
  bool isDialogOpen() => _state.currentScene == 'dialog';
  String currentScene() => _state.currentScene;
  String currentMap() => _state.currentMap;
  bool inventoryFull() => _state.inventoryFull;
  bool equipmentBroken() => false;
  bool playerDead() => _state.currentHp <= 0 && _state.currentHp != 0;
}
