import '../automation/automation_action.dart';
import '../decision/goal.dart';
import '../workflow/workflow.dart';
import 'game_profile.dart';

/// Interface implemented by game plugins loaded by the platform.
abstract class GamePlugin {
  /// Unique plugin identifier.
  String get id;

  /// Internal plugin implementation name.
  String get name;

  /// Localized user-facing plugin display name.
  String get displayName => name;

  /// Called when the plugin is loaded into the platform.
  Future<void> onLoad();

  /// Called when the plugin is unloaded from the platform.
  Future<void> onUnload();

  /// Creates the plugin workflow for the current session.
  Workflow createWorkflow();

  /// Detects the active character. Plugins own all game-specific parsing.
  Future<CharacterProfile> detectCharacter();

  /// Automation actions available for generated per-device logic UI.
  List<AutomationActionDefinition> getAutomationActions();

  /// Task profiles available for this plugin.
  List<TaskProfile> createTaskProfiles();

  /// Creates perception-driven goals for the current session.
  List<Goal> createGoals();
}

/// Immutable plugin metadata used by the platform UI and domain services.
class Plugin {
  /// Unique plugin identifier.
  final String id;

  /// Internal plugin implementation name.
  final String name;

  /// Localized user-facing plugin display name.
  final String displayName;

  /// Plugin semantic version string.
  final String version;

  /// Plugin author name.
  final String author;

  /// Short plugin description.
  final String description;

  /// Optional icon asset or symbolic icon identifier.
  final String icon;

  /// Whether the plugin is enabled in the platform.
  final bool enabled;

  /// Runtime plugin implementation.
  final GamePlugin? implementation;

  /// Creates immutable plugin metadata.
  const Plugin({
    required this.id,
    required this.name,
    String? displayName,
    required this.version,
    required this.author,
    required this.description,
    required this.icon,
    required this.enabled,
    this.implementation,
  }) : displayName = displayName ?? name;
}
