/// Per-emulator automation profile stored by the local database.
class AutomationProfile {
  /// Creates an automation profile.
  const AutomationProfile({required this.id, required this.emulatorId, required this.enabledTaskIds});

  final String id;
  final String emulatorId;
  final Set<String> enabledTaskIds;

  /// Whether a task should be scheduled.
  bool isEnabled(String taskId) => enabledTaskIds.contains(taskId);
}
