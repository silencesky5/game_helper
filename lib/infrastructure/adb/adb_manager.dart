import 'dart:convert';
import 'dart:io';

import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';

/// High-level ADB runtime status used by discovery, dashboard, and automation guards.
enum AdbRuntimeStatus {
  /// No adb executable could be found or launched.
  notFound,

  /// An adb candidate was found but `adb version` failed.
  invalid,

  /// `adb version` succeeded, but connection has not found a device yet.
  available,

  /// `adb version` and `adb devices` both succeeded with at least one online device.
  connected,

  /// adb is executable, but `adb devices` reported no online devices.
  noDevice,
}

/// Immutable snapshot of the latest ADB validation state.
class AdbValidationSnapshot {
  /// Creates a validation snapshot.
  const AdbValidationSnapshot({
    required this.status,
    required this.lastValidation,
    this.path,
    this.version,
    this.connectedDevices = 0,
    this.message,
  });

  /// Empty initial snapshot before validation has run.
  const AdbValidationSnapshot.initial()
      : status = AdbRuntimeStatus.notFound,
        lastValidation = null,
        path = null,
        version = null,
        connectedDevices = 0,
        message = 'ADB executable not found. Please configure adb.exe path.';

  final AdbRuntimeStatus status;
  final DateTime? lastValidation;
  final String? path;
  final String? version;
  final int connectedDevices;
  final String? message;

  bool get executableAvailable => status == AdbRuntimeStatus.available || status == AdbRuntimeStatus.connected || status == AdbRuntimeStatus.noDevice;
  bool get automationReady => status == AdbRuntimeStatus.connected && connectedDevices > 0;

  String get statusLabel => switch (status) {
        AdbRuntimeStatus.notFound => 'ADB Not Found',
        AdbRuntimeStatus.invalid => 'ADB Invalid',
        AdbRuntimeStatus.available => 'ADB Available',
        AdbRuntimeStatus.connected => 'ADB Connected',
        AdbRuntimeStatus.noDevice => 'No Device',
      };
}

/// Centralized ADB discovery, validation, configuration, and execution.
class ADBManager {
  /// Creates an ADB manager.
  ADBManager({this.logger, File? configFile}) : _configFile = configFile ?? File('config/adb.json');

  /// Optional runtime logger for ADB events.
  final LoggerService? logger;
  final File _configFile;

  String? _adbPath;
  String? _adbVersion;
  int _connectedDevices = 0;
  AdbValidationSnapshot _snapshot = const AdbValidationSnapshot.initial();

  /// Currently selected ADB executable path, when discovered or configured.
  String? get adbPath => _adbPath;

  /// Version text returned by `adb version`, when validation succeeds.
  String? get adbVersion => _adbVersion;

  /// Latest full validation state.
  AdbValidationSnapshot get validationSnapshot => _snapshot;

  /// Number of online devices in the latest `adb devices` validation.
  int get connectedDevices => _connectedDevices;

  /// Whether the selected ADB executable was validated successfully.
  bool get isAvailable => _snapshot.executableAvailable;

  /// Human-readable connection status for settings panels.
  String get connectionStatus => _snapshot.statusLabel;

  /// Locates adb using config, LDPlayer installs, Android SDK, then PATH.
  Future<String?> locateADB({bool forceRescan = false}) async {
    logger?.log(LogLevel.info, '[ADB] Discovery Started');

    final candidates = <String>[];
    if (!forceRescan) {
      final configuredPath = await _readConfiguredPath();
      if (configuredPath != null) candidates.add(configuredPath);
    }
    candidates.addAll(_ldPlayerCandidates());
    candidates.add(_androidSdkCandidate());
    candidates.add(_pathCandidate());

    for (final candidate in candidates.where((path) => path.trim().isNotEmpty).toSet()) {
      logger?.log(LogLevel.info, '[ADB] Candidate:\n$candidate');
      final validation = await validateExecutable(candidate);
      if (validation) {
        await _saveConfiguredPath(candidate);
        logger?.log(LogLevel.info, '[ADB] Ready');
        return candidate;
      }
    }

    _updateSnapshot(AdbRuntimeStatus.notFound, message: 'ADB executable not found. Please configure adb.exe path.');
    logger?.log(LogLevel.warning, '[ADB] Validation Failed\nReason:\nadb executable not found');
    return null;
  }

  /// Validates [path] by executing `adb version` and requiring exit code 0.
  Future<bool> validateExecutable([String? path]) async {
    if (path == null && _adbPath == null) {
      return await locateADB() != null;
    }
    final candidate = (path ?? _adbPath)?.trim();
    if (candidate == null || candidate.isEmpty) {
      _updateSnapshot(AdbRuntimeStatus.notFound, message: 'ADB executable not found. Please configure adb.exe path.');
      return false;
    }

    try {
      final result = await Process.run(candidate, const <String>['version']);
      if (result.exitCode == 0) {
        _adbPath = candidate;
        _adbVersion = _extractVersion(result.stdout.toString());
        _updateSnapshot(AdbRuntimeStatus.available, message: 'ADB is available. No Android device detected.');
        logger?.log(LogLevel.info, '[ADB] Validation Success\nVersion:\n$_adbVersion');
        return true;
      }
      _updateSnapshot(AdbRuntimeStatus.invalid, path: candidate, message: 'ADB execution failed. Check adb path and permissions.');
      logger?.log(LogLevel.warning, '[ADB] Validation Failed\nReason:\nadb version returned exit code ${result.exitCode}');
      return false;
    } on ProcessException catch (error) {
      final status = _missingExecutable(candidate) ? AdbRuntimeStatus.notFound : AdbRuntimeStatus.invalid;
      _updateSnapshot(
        status,
        path: candidate,
        message: status == AdbRuntimeStatus.notFound ? 'ADB executable not found. Please configure adb.exe path.' : 'ADB execution failed. Check adb path and permissions.',
      );
      logger?.log(LogLevel.warning, '[ADB] Validation Failed\nReason:\n$error');
      return false;
    }
  }

  /// Backwards-compatible executable validation entry point.
  Future<bool> validateADB() => validateExecutable();

  /// Validates adb executability and requires at least one connected online device.
  Future<bool> validateConnection() async {
    if (!await validateExecutable()) return false;
    try {
      final result = await Process.run(_adbPath!, const <String>['devices']);
      if (result.exitCode != 0) {
        _updateSnapshot(AdbRuntimeStatus.invalid, message: 'ADB execution failed. Check adb path and permissions.');
        logger?.log(LogLevel.warning, '[ADB] Validation Failed\nReason:\nadb devices returned exit code ${result.exitCode}');
        return false;
      }
      _connectedDevices = _countOnlineDevices(result.stdout.toString());
      final status = _connectedDevices > 0 ? AdbRuntimeStatus.connected : AdbRuntimeStatus.noDevice;
      _updateSnapshot(status, message: _connectedDevices > 0 ? null : 'ADB is available. No Android device detected.');
      logger?.log(LogLevel.info, '[ADB] Devices:\n$_connectedDevices');
      if (_connectedDevices > 0) logger?.log(LogLevel.info, '[ADB] Ready');
      return _connectedDevices > 0;
    } on ProcessException catch (error) {
      _updateSnapshot(AdbRuntimeStatus.invalid, message: 'ADB execution failed. Check adb path and permissions.');
      logger?.log(LogLevel.warning, '[ADB] Validation Failed\nReason:\n$error');
      return false;
    }
  }

  /// Executes adb with [arguments]. All ADB process execution must use this method.
  Future<ProcessResult> execute(List<String> arguments, {bool binary = false}) async {
    if (_adbPath == null && await locateADB() == null) {
      logger?.log(LogLevel.error, 'ADB Execution Failed: adb executable not found');
      throw const ProcessException('adb', <String>[], 'adb executable not found');
    }
    try {
      return await Process.run(_adbPath!, arguments, stdoutEncoding: binary ? null : systemEncoding);
    } on ProcessException catch (error) {
      _updateSnapshot(AdbRuntimeStatus.invalid, message: 'ADB execution failed. Check adb path and permissions.');
      logger?.log(LogLevel.error, 'ADB Execution Failed: $error');
      rethrow;
    }
  }

  /// Manually changes the ADB path, persists it, and validates it.
  Future<bool> setADBPath(String path) async {
    _adbPath = path.trim();
    logger?.log(LogLevel.info, 'ADB Path Changed: $_adbPath');
    await _saveConfiguredPath(_adbPath!);
    return validateExecutable();
  }

  /// Rescans known locations and validates the discovered executable and devices.
  Future<bool> rescan() async {
    await locateADB(forceRescan: true);
    return validateConnection();
  }

  Future<String?> _readConfiguredPath() async {
    try {
      if (!await _configFile.exists()) return null;
      final json = jsonDecode(await _configFile.readAsString()) as Map<String, dynamic>;
      return json['adbPath'] as String?;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _saveConfiguredPath(String path) async {
    await _configFile.parent.create(recursive: true);
    await _configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(<String, String>{'adbPath': path}));
  }

  List<String> _ldPlayerCandidates() {
    if (!Platform.isWindows) return const <String>[];
    final candidates = <String>['C:\\LDPlayer\\LDPlayer9\\adb.exe'];
    for (final root in <String>['C:\\LDPlayer', 'C:\\Program Files\\LDPlayer']) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(followLinks: false).whereType<Directory>()) {
        candidates.add('${entity.path}\\adb.exe');
      }
    }
    return candidates;
  }

  String _androidSdkCandidate() {
    if (!Platform.isWindows) return '';
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) return '';
    return '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe';
  }

  String _pathCandidate() => Platform.isWindows ? 'adb.exe' : 'adb';

  String _extractVersion(String stdout) {
    final lines = stdout.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty);
    return lines.isEmpty ? 'Unknown' : lines.first;
  }

  int _countOnlineDevices(String stdout) => stdout
      .split('\n')
      .skip(1)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('*'))
      .where((line) {
        final parts = line.split(RegExp(r'\s+'));
        return parts.length > 1 && parts[1] == 'device';
      })
      .length;

  bool _missingExecutable(String candidate) {
    if (candidate == 'adb' || candidate == 'adb.exe') return true;
    if (candidate.contains(Platform.pathSeparator) || candidate.contains('\\')) {
      return !File(candidate).existsSync();
    }
    return false;
  }

  void _updateSnapshot(AdbRuntimeStatus status, {String? path, String? message}) {
    if (status == AdbRuntimeStatus.notFound || status == AdbRuntimeStatus.invalid) {
      _connectedDevices = 0;
      if (status == AdbRuntimeStatus.notFound) _adbVersion = null;
    }
    _snapshot = AdbValidationSnapshot(
      status: status,
      lastValidation: DateTime.now(),
      path: path ?? _adbPath,
      version: _adbVersion,
      connectedDevices: _connectedDevices,
      message: message,
    );
  }
}
