import '../action/device_action.dart';
import '../automation/automation_context.dart';
import '../automation/automation_session.dart';
import '../command/command_queue.dart';
import '../core/result.dart';
import '../perception/perception_types.dart';
import '../vision/game_state.dart';
import 'action_plan.dart';
import 'decision_config.dart';
import 'decision_logger.dart';
import 'decision_state.dart';
import 'goal.dart';

/// Executes plugin goals from perception-driven action plans.
class DecisionEngine {
  DecisionEngine({required this.context, required this.config, required this.repository}) : _logger = DecisionLogger(context.loggerService);

  final AutomationContext context;
  final DecisionConfig config;
  final DecisionRepository repository;
  final DecisionLogger _logger;

  ActionPlan decide(Goal goal, PerceptionResult? perception) => goal.nextAction(perception);

  ActionPlan nextAction(Goal goal, PerceptionResult? perception) => decide(goal, perception);

  Future<void> executeGoal(AutomationSession session, Goal goal) async {
    _logger.goalStarted(session.device.id, goal.name);
    final DateTime startedAt = DateTime.now();
    var retryCount = 0;
    while (DateTime.now().difference(startedAt) < config.timeout) {
      final PerceptionResult? perception = context.perceptionRepository.lastResult(session.device.id);
      final ActionPlan plan = nextAction(goal, perception);
      final DecisionStage stage = _stageFor(perception, plan.completed);
      repository.save(DecisionStatus(
        deviceId: session.device.id,
        currentGoal: goal.name,
        currentDecision: plan.name,
        currentAction: plan.steps.isEmpty ? 'Finish' : plan.steps.first.label,
        retryCount: retryCount,
        lastDecisionTime: DateTime.now(),
        stage: stage,
      ));
      _logger.decisionCreated(session.device.id, '${goal.name} -> ${plan.name}');
      if (plan.completed) {
        _logger.goalFinished(session.device.id, goal.name);
        return;
      }
      final bool success = await _executePlan(session, plan);
      if (!success) {
        retryCount++;
        if (retryCount > config.retryCount) break;
        _logger.retry(session.device.id, retryCount);
      }
      await Future<void>.delayed(config.decisionInterval);
    }
    _logger.recoveryTriggered(session.device.id, 'Timeout or retry limit reached for ${goal.name}');
    repository.save(DecisionStatus(
      deviceId: session.device.id,
      currentGoal: goal.name,
      currentDecision: 'Abort',
      currentAction: 'Abort',
      retryCount: retryCount,
      lastDecisionTime: DateTime.now(),
      stage: DecisionStage.aborted,
    ));
  }

  Future<bool> _executePlan(AutomationSession session, ActionPlan plan) async {
    for (final PlanStep step in plan.steps) {
      repository.save(repository.statusFor(session.device.id)!.copyWithAction(step.label));
      if (step is WaitPlanStep) {
        await Future<void>.delayed(step.duration);
      } else if (step is RefreshPerceptionStep) {
        final result = await context.screenshotService.captureForVision(session.device);
        if (result is Failure) return false;
        await result.fold((screenshot) async {
          context.screenshotRepository.save(screenshot);
          await context.perceptionService.analyze(session.device.id);
        }, (error) async => false);
      } else if (step is DevicePlanStep) {
        final queue = CommandQueue()..enqueue(step.action);
        final Result<void> result = await queue.execute(ActionContext(session: session, deviceControlService: context.deviceControlService, logger: context.loggerService));
        if (result.isFailure) return false;
      }
      _logger.actionExecuted(session.device.id, step.label);
    }
    return true;
  }

  DecisionStage _stageFor(PerceptionResult? perception, bool completed) {
    if (completed) return DecisionStage.goalCompleted;
    return switch (perception?.currentState) {
      GameState.loading => DecisionStage.loading,
      GameState.mainMenu => DecisionStage.mainMenu,
      _ => DecisionStage.unknown,
    };
  }
}

extension on DecisionStatus {
  DecisionStatus copyWithAction(String action) => DecisionStatus(
        deviceId: deviceId,
        currentGoal: currentGoal,
        currentDecision: currentDecision,
        currentAction: action,
        retryCount: retryCount,
        lastDecisionTime: DateTime.now(),
        stage: stage,
      );
}
