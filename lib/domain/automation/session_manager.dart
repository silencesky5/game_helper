import '../device/device.dart';
import 'automation_session.dart';

/// Creates and tracks one automation session per Android device.
class SessionManager {
  final Map<String, AutomationSession> _sessionsByDeviceId = <String, AutomationSession>{};

  /// Current sessions, ordered by creation.
  List<AutomationSession> get sessions => List<AutomationSession>.unmodifiable(_sessionsByDeviceId.values);

  /// Creates a session for [device] or returns the existing one.
  AutomationSession createSession(Device device) {
    return _sessionsByDeviceId.putIfAbsent(
      device.id,
      () => AutomationSession(
        id: 'Session ${_sessionsByDeviceId.length + 1}',
        device: device,
      ),
    );
  }

  /// Replaces a session snapshot.
  void updateSession(AutomationSession session) {
    _sessionsByDeviceId[session.device.id] = session;
  }

  /// Removes all sessions.
  void clear() {
    _sessionsByDeviceId.clear();
  }
}
