class ConsoleLogger implements LoggerService {
  @override
  void info(String message) {
    print("[INFO] $message");
  }

  @override
  void warning(String message) {
    print("[WARNING] $message");
  }

  @override
  void error(String message) {
    print("[ERROR] $message");
  }
}