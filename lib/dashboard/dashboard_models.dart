import '../emulator/emulator.dart';

/// Lightweight row model for the clean emulator dashboard.
class DashboardEmulatorRow {
  /// Creates a dashboard row.
  const DashboardEmulatorRow({required this.emulator, this.character = 'Unknown', this.lastTask = 'None', this.runCount = 0, this.startedAt});

  final Emulator emulator;
  final String character;
  final String lastTask;
  final int runCount;
  final DateTime? startedAt;
}
