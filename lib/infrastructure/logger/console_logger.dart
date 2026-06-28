import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';

/// Logger implementation that writes messages to the console.
class ConsoleLogger implements LoggerService {
  /// Writes a log [message] with the provided [level] to the console.
  @override
  void log(
    LogLevel level,
    String message,
  ) {
    print('[${level.name.toUpperCase()}] $message');
  }
}
