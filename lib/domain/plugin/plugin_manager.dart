import '../action/device_action.dart';
import '../decision/action_plan.dart';
import '../decision/goal.dart';
import '../vision/game_state.dart';
import '../workflow/steps/delay_step.dart';
import '../workflow/steps/log_step.dart';
import '../workflow/workflow.dart';
import '../workflow/workflow_step.dart';
import 'game_profile.dart';
import 'plugin.dart';
import 'plugin_repository.dart';

/// Coordinates plugin loading for application features.
class PluginManager {
  final PluginRepository _repository;
  List<Plugin> _plugins = const <Plugin>[];

  /// Creates a plugin manager with a replaceable [repository].
  PluginManager({PluginRepository? repository})
      : _repository = repository ?? const MockPluginRepository();

  /// Loads plugin metadata into memory.
  Future<void> initialize() async {
    _plugins = List<Plugin>.unmodifiable(await _repository.loadPlugins());
    for (final Plugin plugin in _plugins) {
      await plugin.implementation?.onLoad();
    }
  }

  /// Installed plugins loaded by [initialize].
  List<Plugin> get plugins => _plugins;

  /// Returns the loaded plugin with [id], or null when it does not exist.
  Plugin? getPlugin(String id) {
    for (final Plugin plugin in _plugins) {
      if (plugin.id == id) {
        return plugin;
      }
    }

    return null;
  }

  /// Loads the workflow for [plugin].
  Future<Workflow> getWorkflow(Plugin plugin) async {
    return plugin.implementation?.createWorkflow() ?? _repository.loadWorkflow(plugin);
  }
}

class LaunchGameGoal extends Goal {
  const LaunchGameGoal({this.packageName = 'com.minejourney.game', this.activityName});

  final String packageName;
  final String? activityName;

  @override
  String get id => 'launch_game';

  @override
  String get name => 'Launch Game';

  @override
  ActionPlan nextAction(perception) {
    if (perception?.currentState == GameState.loading || perception?.currentState == GameState.mainMenu) {
      return ActionPlan.finished;
    }
    return ActionPlan(
      name: 'Launch App then refresh perception',
      steps: <PlanStep>[
        DevicePlanStep(LaunchAppAction(packageName, activityName: activityName)),
        const WaitPlanStep(Duration(seconds: 2)),
        const RefreshPerceptionStep(),
      ],
    );
  }
}

class WaitMainMenuGoal extends Goal {
  const WaitMainMenuGoal();

  @override
  String get id => 'wait_main_menu';

  @override
  String get name => 'Wait Main Menu';

  @override
  ActionPlan nextAction(perception) {
    if (perception?.currentState == GameState.mainMenu) return ActionPlan.finished;
    return const ActionPlan(
      name: 'Wait for MainMenu state',
      steps: <PlanStep>[WaitPlanStep(Duration(seconds: 1)), RefreshPerceptionStep()],
    );
  }
}

/// Mine Journey MVP plugin that returns launch and wait-main-menu goals.
class MineJourneyPlugin implements GamePlugin {
  /// Creates the Mine Journey starter plugin.
  const MineJourneyPlugin();

  @override
  String get id => 'mine_journey';

  @override
  String get name => 'MineJourneyPlugin';

  @override
  String get displayName => '礦山之旅';

  @override
  Future<void> onLoad() async {}

  @override
  Future<void> onUnload() async {}

  @override
  Future<CharacterProfile> detectCharacter() async {
    return const CharacterProfile(name: '小礦工', level: 'Lv58');
  }

  @override
  List<TaskProfile> createTaskProfiles() => <TaskProfile>[
        TaskProfile(
          id: 'daily',
          name: '每日任務',
          description: '登入、簽到、採礦、整理背包、離線。',
          workflow: createWorkflow(),
        ),
        TaskProfile(
          id: 'mining',
          name: '純採礦',
          description: '登入、採礦、販售、採礦。',
          workflow: createWorkflow(),
        ),
        TaskProfile(
          id: 'boss',
          name: 'Boss',
          description: '登入、Boss、採礦、整理背包。',
          workflow: createWorkflow(),
        ),
        TaskProfile(
          id: 'event',
          name: '活動',
          description: '登入、活動、Boss、採礦。',
          workflow: createWorkflow(),
        ),
        TaskProfile(
          id: 'custom',
          name: '自訂...',
          description: '未來可透過 Workflow Editor 自訂。',
          workflow: createWorkflow(),
        ),
      ];

  @override
  List<Goal> createGoals() => const <Goal>[LaunchGameGoal(), WaitMainMenuGoal()];

  @override
  Workflow createWorkflow() {
    return const Workflow(
      id: 'mine_journey_dummy_workflow',
      name: 'Mine Journey Dummy Workflow',
      description: 'Dummy Sprint 1 workflow with only log and delay steps.',
      version: '1.0.0',
      steps: <WorkflowStep>[
        LogStep(id: 'log_start', message: 'Dummy workflow started'),
        DelayStep(id: 'delay_demo', milliseconds: 250),
        LogStep(id: 'log_finish', message: 'Dummy workflow finished'),
      ],
    );
  }
}

/// Mock plugin repository used until filesystem discovery is implemented.
class MockPluginRepository implements PluginRepository {
  /// Creates a mock plugin repository.
  const MockPluginRepository();

  @override
  Future<List<Plugin>> loadPlugins() async {
    return const <Plugin>[
      Plugin(
        id: 'unassigned',
        name: 'UnassignedPlugin',
        displayName: '未指定',
        version: 'N/A',
        author: 'Game Helper Platform',
        description: 'No game plugin is assigned to this device.',
        icon: 'block',
        enabled: true,
      ),
      Plugin(
        id: 'mine_journey',
        name: 'MineJourneyPlugin',
        displayName: '礦山之旅',
        version: '1.0.0',
        author: 'Game Helper Team',
        description: 'Mine Journey MVP launch and wait-main-menu pipeline.',
        icon: 'extension',
        enabled: true,
        implementation: MineJourneyPlugin(),
      ),
      Plugin(
        id: 'lineage_m',
        name: 'LineageMPlugin',
        displayName: '天堂M',
        version: 'Not installed',
        author: 'Plugin Marketplace',
        description: 'Marketplace placeholder for a future Lineage M plugin.',
        icon: 'extension',
        enabled: false,
      ),
      Plugin(
        id: 'ro',
        name: 'ROPlugin',
        displayName: 'RO',
        version: 'Not installed',
        author: 'Plugin Marketplace',
        description: 'Marketplace placeholder for a future RO plugin.',
        icon: 'extension',
        enabled: false,
      ),
      Plugin(
        id: 'maplestory_m',
        name: 'MapleStoryMPlugin',
        displayName: '楓之谷M',
        version: 'Not installed',
        author: 'Plugin Marketplace',
        description: 'Marketplace placeholder for a future MapleStory M plugin.',
        icon: 'extension',
        enabled: false,
      ),
    ];
  }

  @override
  Future<Workflow> loadWorkflow(Plugin plugin) async {
    return const Workflow(
      id: 'mine_journey_dummy_workflow',
      name: 'Mine Journey Dummy Workflow',
      description: 'Dummy Sprint 1 workflow with only log and delay steps.',
      version: '1.0.0',
      steps: <WorkflowStep>[
        LogStep(id: 'log_start', message: 'Dummy workflow started'),
        DelayStep(id: 'delay_demo', milliseconds: 250),
        LogStep(id: 'log_finish', message: 'Dummy workflow finished'),
      ],
    );
  }
}
