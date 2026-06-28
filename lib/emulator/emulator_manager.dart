import 'emulator.dart';

/// Detects and manages LDPlayer instances.
class EmulatorManager {
  /// Creates an emulator manager with optional seeded devices.
  EmulatorManager({List<Emulator>? emulators}) : _emulators = List<Emulator>.of(emulators ?? _demoEmulators);

  final List<Emulator> _emulators;

  /// Returns the current LDPlayer inventory.
  Future<List<Emulator>> detectLdPlayers() async => List<Emulator>.unmodifiable(_emulators);

  /// Starts an emulator.
  Future<Emulator> start(String id) async => _update(id, EmulatorStatus.running);

  /// Stops an emulator.
  Future<Emulator> stop(String id) async => _update(id, EmulatorStatus.offline);

  /// Restarts an emulator.
  Future<Emulator> restart(String id) async => _update(id, EmulatorStatus.running);

  Future<Emulator> _update(String id, EmulatorStatus status) async {
    final index = _emulators.indexWhere((emulator) => emulator.id == id);
    if (index < 0) throw StateError('Emulator not found: $id');
    final updated = _emulators[index].copyWith(status: status);
    _emulators[index] = updated;
    return updated;
  }

  static const List<Emulator> _demoEmulators = <Emulator>[
    Emulator(id: 'ldplayer-1', name: 'LDPlayer 1', adbPort: 5555, status: EmulatorStatus.running),
    Emulator(id: 'ldplayer-2', name: 'LDPlayer 2', adbPort: 5557, status: EmulatorStatus.offline),
  ];
}
