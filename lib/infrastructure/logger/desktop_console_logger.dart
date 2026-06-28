import 'package:flutter/foundation.dart';

import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';

/// Logger implementation that stores recent desktop console events for the UI.
class DesktopConsoleLogger extends ChangeNotifier implements LoggerService {
  /// Creates a logger with a bounded in-memory history.
  DesktopConsoleLogger({this.capacity = 300});

  /// Maximum number of log entries retained for the dashboard.
  final int capacity;

  final List<String> _entries = <String>[];

  /// Recent log entries in chronological order.
  List<String> get entries => List<String>.unmodifiable(_entries);

  @override
  void log(LogLevel level, String message) {
    final String entry = '[${DateTime.now().toLocal().toString().split('.').first}] [${level.name.toUpperCase()}] $message';
    debugPrint(entry);
    _entries.add(entry);
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
    notifyListeners();
  }
}
