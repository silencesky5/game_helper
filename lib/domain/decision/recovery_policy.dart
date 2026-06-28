/// Recovery behavior available to the decision engine.
enum RecoveryStrategy { retry, timeout, abort }

/// Retry and timeout settings for goal execution.
class RecoveryPolicy {
  const RecoveryPolicy({required this.strategy, required this.maxRetries, required this.timeout});

  final RecoveryStrategy strategy;
  final int maxRetries;
  final Duration timeout;
}
