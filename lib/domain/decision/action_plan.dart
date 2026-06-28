import '../action/device_action.dart';

/// One executable item in a decision plan.
sealed class PlanStep {
  const PlanStep(this.label);
  final String label;
}

/// Executes a device action through the command queue.
class DevicePlanStep extends PlanStep {
  DevicePlanStep(this.action) : super(action.label);
  final DeviceAction action;
}

/// Captures a new screenshot and refreshes perception.
class RefreshPerceptionStep extends PlanStep {
  const RefreshPerceptionStep() : super('Refresh Screenshot');
}

/// Waits before the next decision.
class WaitPlanStep extends PlanStep {
  const WaitPlanStep(this.duration) : super('Wait');
  final Duration duration;
}

/// Ordered action plan created by a goal.
class ActionPlan {
  const ActionPlan({required this.name, required this.steps, this.completed = false});

  final String name;
  final List<PlanStep> steps;
  final bool completed;

  static const ActionPlan finished = ActionPlan(name: 'Finish', steps: <PlanStep>[], completed: true);
}
