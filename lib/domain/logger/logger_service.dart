import 'logger.dart';

/// Defines the contract for platform logging services.
abstract class LoggerService {
  /// Writes a log [message] with the provided [level].
  void log(
    LogLevel level,
    String message,
  );
}
