/// Shared game state observed through the StateManager.
class GameState {
  /// Creates immutable game state.
  const GameState({
    this.currentScene = 'unknown',
    this.currentMap = 'unknown',
    this.currentCharacter = 'unknown',
    this.currentHp = 0,
    this.currentMp = 0,
    this.currentPosition = 'unknown',
    this.inventoryFull = false,
    this.mining = false,
    this.battle = false,
    this.boss = false,
    this.disconnected = false,
  });

  final String currentScene;
  final String currentMap;
  final String currentCharacter;
  final int currentHp;
  final int currentMp;
  final String currentPosition;
  final bool inventoryFull;
  final bool mining;
  final bool battle;
  final bool boss;
  final bool disconnected;

  GameState copyWith({String? currentScene, String? currentMap, String? currentCharacter, int? currentHp, int? currentMp, String? currentPosition, bool? inventoryFull, bool? mining, bool? battle, bool? boss, bool? disconnected}) {
    return GameState(
      currentScene: currentScene ?? this.currentScene,
      currentMap: currentMap ?? this.currentMap,
      currentCharacter: currentCharacter ?? this.currentCharacter,
      currentHp: currentHp ?? this.currentHp,
      currentMp: currentMp ?? this.currentMp,
      currentPosition: currentPosition ?? this.currentPosition,
      inventoryFull: inventoryFull ?? this.inventoryFull,
      mining: mining ?? this.mining,
      battle: battle ?? this.battle,
      boss: boss ?? this.boss,
      disconnected: disconnected ?? this.disconnected,
    );
  }
}
