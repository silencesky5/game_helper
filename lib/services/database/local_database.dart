import '../../automation/engine/automation_profile.dart';

/// Local profile storage abstraction.
class LocalDatabase {
  /// Creates an in-memory local database.
  LocalDatabase({Map<String, AutomationProfile>? profiles}) : _profiles = profiles ?? <String, AutomationProfile>{};

  final Map<String, AutomationProfile> _profiles;

  /// Saves a profile.
  Future<void> saveProfile(AutomationProfile profile) async => _profiles[profile.emulatorId] = profile;

  /// Loads a profile for the emulator, or creates a default daily profile.
  Future<AutomationProfile> loadProfile(String emulatorId) async {
    return _profiles[emulatorId] ??
        AutomationProfile(
          id: 'default-$emulatorId',
          emulatorId: emulatorId,
          enabledTaskIds: const <String>{'login', 'sign', 'mail', 'shop', 'stone', 'inventory', 'repair', 'mine'},
        );
  }
}
