import '../logger/logger.dart';
import '../logger/logger_service.dart';

class DecisionLogger {
  const DecisionLogger(this._logger);
  final LoggerService _logger;

  void goalStarted(String deviceId, String goal) => _log('Goal Started', deviceId, goal);
  void decisionCreated(String deviceId, String decision) => _log('Decision Created', deviceId, decision);
  void actionExecuted(String deviceId, String action) => _log('Action Executed', deviceId, action);
  void retry(String deviceId, int count) => _log('Retry', deviceId, 'attempt $count');
  void goalFinished(String deviceId, String goal) => _log('Goal Finished', deviceId, goal);
  void recoveryTriggered(String deviceId, String reason) => _log('Recovery Triggered', deviceId, reason);

  void _log(String event, String deviceId, String message) {
    _logger.log(LogLevel.info, '[Decision] $event device=$deviceId $message');
  }
}
