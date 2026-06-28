/// ADB command boundary used by action and emulator services.
abstract class AdbService {
  /// Runs an adb command and returns stdout.
  Future<String> run(List<String> arguments);
}
