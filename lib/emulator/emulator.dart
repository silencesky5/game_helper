/// Runtime status for a managed Android emulator.
enum EmulatorStatus { offline, starting, running, stopping, error }

/// Emulator metadata shown by the dashboard and consumed by automation.
class Emulator {
  /// Creates immutable emulator metadata.
  const Emulator({required this.id, required this.name, required this.adbPort, this.status = EmulatorStatus.offline, this.currentTask = 'Idle', this.automationProfileId = 'default'});

  final String id;
  final String name;
  final int adbPort;
  final EmulatorStatus status;
  final String currentTask;
  final String automationProfileId;

  Emulator copyWith({String? id, String? name, int? adbPort, EmulatorStatus? status, String? currentTask, String? automationProfileId}) {
    return Emulator(
      id: id ?? this.id,
      name: name ?? this.name,
      adbPort: adbPort ?? this.adbPort,
      status: status ?? this.status,
      currentTask: currentTask ?? this.currentTask,
      automationProfileId: automationProfileId ?? this.automationProfileId,
    );
  }
}
