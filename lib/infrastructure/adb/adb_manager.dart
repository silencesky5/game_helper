import 'dart:convert';
import 'dart:io';

import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';

/// Centralized ADB discovery, validation, configuration, and execution.
class ADBManager {
  /// Creates an ADB manager.
  ADBManager({this.logger, File? configFile}) : _configFile = configFile ?? File('config/adb.json');

  /// Optional runtime logger for ADB events.
  final LoggerService? logger;
  final File _configFile;

  String? _adbPath;
  String? _adbVersion;
  bool _available = false;

  /// Currently selected ADB executable path, when discovered or configured.
  String? get adbPath => _adbPath;

  /// Version text returned by `adb version`, when validation succeeds.
  String? get adbVersion => _adbVersion;

  /// Whether the selected ADB executable was validated successfully.
  bool get isAvailable => _available;

  /// Human-readable connection status for settings panels.
  String get connectionStatus => _available ? 'Available' : 'Unavailable';

  /// Locates adb using config, LDPlayer installs, Android SDK, then PATH.
  Future<String?> locateADB({bool forceRescan = false}) async {
    logger?.log(LogLevel.info, 'ADB Discovery Started');

    final candidates = <String>[];
    if (!forceRescan) {
      final configuredPath = await _readConfiguredPath();
      if (configuredPath != null) candidates.add(configuredPath);
    }
    candidates.addAll(_ldPlayerCandidates());
    candidates.add(_androidSdkCandidate());
    candidates.add(_pathCandidate());

    for (final candidate in candidates.where((path) => path.trim().isNotEmpty)) {
      if (await _candidateExists(candidate)) {
        _adbPath = candidate;
        logger?.log(LogLevel.info, 'ADB Found: $candidate');
        await _saveConfiguredPath(candidate);
        return candidate;
      }
    }

    _adbPath = null;
    _adbVersion = null;
    _available = false;
    logger?.log(LogLevel.warning, 'ADB Validation Failed: adb executable not found');
    return null;
  }

  /// Validates the selected ADB executable by running `adb version`.
  Future<bool> validateADB() async {
    final path = _adbPath ?? await locateADB();
    if (path == null) {
      _available = false;
      logger?.log(LogLevel.warning, 'ADB Validation Failed: adb executable not found');
      return false;
    }

    try {
      final result = await Process.run(path, const <String>['version']);
      if (result.exitCode == 0) {
        _adbVersion = result.stdout.toString().trim().split('\n').first.trim();
        _available = true;
        logger?.log(LogLevel.info, 'ADB Validation Success: $_adbVersion');
        return true;
      }
      _available = false;
      logger?.log(LogLevel.warning, 'ADB Validation Failed: ${result.stderr}');
      return false;
    } on ProcessException catch (error) {
      _available = false;
      logger?.log(LogLevel.warning, 'ADB Validation Failed: $error');
      return false;
    }
  }

  /// Executes adb with [arguments]. All ADB process execution must use this method.
  Future<ProcessResult> execute(List<String> arguments, {bool binary = false}) async {
    final path = _adbPath ?? await locateADB();
    if (path == null) {
      logger?.log(LogLevel.error, 'ADB Execution Failed: adb executable not found');
      throw const ProcessException('adb', <String>[], 'adb executable not found');
    }
    try {
      return await Process.run(path, arguments, stdoutEncoding: binary ? null : systemEncoding);
    } on ProcessException catch (error) {
      _available = false;
      logger?.log(LogLevel.error, 'ADB Execution Failed: $error');
      rethrow;
    }
  }

  /// Manually changes the ADB path, persists it, and validates it.
  Future<bool> setADBPath(String path) async {
    _adbPath = path.trim();
    logger?.log(LogLevel.info, 'ADB Path Changed: $_adbPath');
    await _saveConfiguredPath(_adbPath!);
    return validateADB();
  }

  /// Rescans known locations and validates the discovered executable.
  Future<bool> rescan() async {
    await locateADB(forceRescan: true);
    return validateADB();
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

  Future<bool> _candidateExists(String path) async {
    if (path == 'adb' || path == 'adb.exe') return true;
    return File(path).exists();
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
}
