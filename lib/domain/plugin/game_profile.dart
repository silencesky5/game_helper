import '../workflow/workflow.dart';

/// Character identity returned by a game plugin after login/state detection.
class CharacterProfile {
  /// Creates immutable character metadata for dashboard display.
  const CharacterProfile({
    required this.name,
    this.level,
    this.server,
    this.loggedIn = true,
  });

  /// Placeholder used before a plugin detects a logged-in character.
  const CharacterProfile.notLoggedIn()
      : name = '未登入',
        level = null,
        server = null,
        loggedIn = false;

  /// Character display name supplied by the plugin.
  final String name;

  /// Optional level text, for example `Lv58`.
  final String? level;

  /// Optional server/shard name.
  final String? server;

  /// Whether the plugin considers the game account logged in.
  final bool loggedIn;

  /// Human-readable dashboard label.
  String get displayName => loggedIn ? name : '未登入';
}

/// A saved task profile describing what a character should do today.
class TaskProfile {
  /// Creates an immutable task profile.
  const TaskProfile({
    required this.id,
    required this.name,
    required this.workflow,
    this.description = '',
  });

  /// Stable task profile identifier.
  final String id;

  /// Human-readable task profile name.
  final String name;

  /// Optional description shown in management UI.
  final String description;

  /// Workflow selected for this task profile.
  final Workflow workflow;
}
