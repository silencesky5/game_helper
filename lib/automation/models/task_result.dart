/// Result status returned by every game automation task.
enum TaskResultStatus {
  /// Task completed successfully.
  success,

  /// Task was intentionally skipped because preconditions were not met.
  skipped,

  /// Task should be retried by the executor.
  retry,

  /// Task failed and should count toward the retry policy.
  failed,

  /// Task exceeded its allotted wait time.
  timeout,
}

/// Immutable task execution result consumed by the automation engine.
class TaskResult {
  /// Creates a task result.
  const TaskResult(this.status, {this.message = ''});

  /// Successful task result.
  const TaskResult.success([String message = '']) : this(TaskResultStatus.success, message: message);

  /// Skipped task result.
  const TaskResult.skipped([String message = '']) : this(TaskResultStatus.skipped, message: message);

  /// Retry task result.
  const TaskResult.retry([String message = '']) : this(TaskResultStatus.retry, message: message);

  /// Failed task result.
  const TaskResult.failed([String message = '']) : this(TaskResultStatus.failed, message: message);

  /// Timeout task result.
  const TaskResult.timeout([String message = '']) : this(TaskResultStatus.timeout, message: message);

  /// Result status.
  final TaskResultStatus status;

  /// Optional diagnostic message.
  final String message;

  /// Whether this result permits the executor to continue immediately.
  bool get canContinue => status == TaskResultStatus.success || status == TaskResultStatus.skipped;

  /// Whether this result should be retried.
  bool get shouldRetry => status == TaskResultStatus.retry || status == TaskResultStatus.failed || status == TaskResultStatus.timeout;
}
