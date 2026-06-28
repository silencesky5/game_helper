/// State transition tracked by the decision engine.
enum DecisionStage { unknown, loading, mainMenu, goalCompleted, aborted }

/// User-visible decision snapshot for the desktop console.
class DecisionStatus {
  const DecisionStatus({
    required this.deviceId,
    required this.currentGoal,
    required this.currentDecision,
    required this.currentAction,
    required this.retryCount,
    required this.lastDecisionTime,
    required this.stage,
  });

  final String deviceId;
  final String currentGoal;
  final String currentDecision;
  final String currentAction;
  final int retryCount;
  final DateTime? lastDecisionTime;
  final DecisionStage stage;
}

class DecisionRepository {
  final Map<String, DecisionStatus> _statuses = <String, DecisionStatus>{};

  DecisionStatus? statusFor(String deviceId) => _statuses[deviceId];

  void save(DecisionStatus status) => _statuses[status.deviceId] = status;
}
