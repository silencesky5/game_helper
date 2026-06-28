import 'dart:async';
import 'dart:io';

import '../../domain/device/device.dart';
import '../../domain/device/device_service.dart';
import '../../domain/logger/logger.dart';
import '../../domain/logger/logger_service.dart';
import 'adb_command_runner.dart';
import 'adb_device.dart';

/// ADB-backed device service for Android emulator discovery.
class AdbDeviceService implements DeviceService {
  /// Creates an ADB-backed device service.
  const AdbDeviceService({
    this.commandRunner = const AdbCommandRunner(),
    this.logger,
    this.commandTimeout = const Duration(seconds: 3),
  });

  /// Runner responsible for invoking adb.
  final AdbCommandRunner commandRunner;

  /// Optional runtime logger for device events.
  final LoggerService? logger;

  /// Maximum time allowed for a single ADB metadata query.
  final Duration commandTimeout;

  @override
  Future<List<Device>> detectDevices() async {
    try {
      final ProcessResult result = await _run(<String>['devices', '-l']);
      if (result.exitCode != 0) {
        logger?.log(LogLevel.warning, 'ADB Timeout: device discovery failed with exit code ${result.exitCode}');
        return const <Device>[];
      }
      final parsedDevices = _parseDevices(result.stdout.toString());
      final enrichedDevices = <Device>[];
      for (var index = 0; index < parsedDevices.length; index += 1) {
        final device = await _withAdbInfo(parsedDevices[index], index);
        enrichedDevices.add(device);
        logger?.log(LogLevel.info, 'Device Connected: ${device.name} (${device.id}) ${device.androidVersion} ${device.resolution}');
      }
      return enrichedDevices;
    } on TimeoutException {
      logger?.log(LogLevel.warning, 'ADB Timeout: device discovery did not finish in ${commandTimeout.inMilliseconds}ms');
      return const <Device>[];
    } on ProcessException {
      return const <Device>[];
    }
  }

  @override
  Future<Device> connect(String deviceId) async {
    final List<Device> devices = await detectDevices();
    return devices.firstWhere(
      (Device device) => device.id == deviceId,
      orElse: () => Device(id: deviceId, name: deviceId, status: DeviceStatus.unknown),
    );
  }

  @override
  Future<void> disconnect(String deviceId) async {
    await _run(<String>['disconnect', deviceId]);
    logger?.log(LogLevel.info, 'Device Disconnected: $deviceId');
  }

  @override
  Future<DeviceStatus> getStatus(String deviceId) async {
    final List<Device> devices = await detectDevices();
    for (final Device device in devices) {
      if (device.id == deviceId) {
        return device.status;
      }
    }
    return DeviceStatus.offline;
  }

  Future<ProcessResult> _run(List<String> arguments) => commandRunner.run(arguments).timeout(commandTimeout);

  Future<Device> _withAdbInfo(Device device, int index) async {
    if (!device.isOnline) {
      return device.copyWith(name: _friendlyName(device, index, device.model));
    }
    final results = await Future.wait<String>(<Future<String>>[
      _shell(device.id, 'getprop ro.build.version.release'),
      _shell(device.id, 'getprop ro.product.manufacturer'),
      _shell(device.id, 'getprop ro.product.model'),
      _shell(device.id, 'wm size'),
    ]);
    final androidVersion = _clean(results[0], fallback: device.androidVersion);
    final manufacturer = _clean(results[1]);
    final model = _clean(results[2], fallback: device.model);
    final resolution = _parseResolution(results[3]);
    return AdbDevice(
      id: device.id,
      name: _friendlyName(device, index, model),
      model: model,
      androidVersion: androidVersion,
      manufacturer: manufacturer,
      resolution: resolution,
      status: device.status,
    );
  }

  Future<String> _shell(String deviceId, String command) async {
    try {
      final result = await _run(<String>['-s', deviceId, 'shell', command]);
      if (result.exitCode != 0) return '';
      return result.stdout.toString();
    } on TimeoutException {
      logger?.log(LogLevel.warning, 'ADB Timeout: $deviceId $command');
      return '';
    } on ProcessException {
      return '';
    }
  }

  List<Device> _parseDevices(String output) {
    return output
        .split('\n')
        .skip(1)
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .where((String line) => !line.startsWith('*'))
        .map(_parseDeviceLine)
        .toList(growable: false);
  }

  Device _parseDeviceLine(String line) {
    final List<String> parts = line.split(RegExp(r'\s+'));
    final String id = parts.first;
    final DeviceStatus status = _statusFromAdb(parts.length > 1 ? parts[1] : 'unknown');
    final String model = _fieldValue(parts, 'model') ?? 'Unknown';
    return AdbDevice(
      id: id,
      name: model == 'Unknown' ? id : model,
      model: model,
      status: status,
    );
  }

  String _friendlyName(Device device, int index, String model) {
    final normalized = '${device.id} $model'.toLowerCase();
    if (normalized.contains('ldplayer') || normalized.contains('leidian')) {
      return 'LDPlayer ${index + 1}';
    }
    if (device.id.startsWith('emulator-')) {
      return model == 'Unknown' ? 'Android Emulator ${index + 1}' : '$model ${index + 1}';
    }
    return model == 'Unknown' ? 'Android Device ${index + 1}' : '$model ${index + 1}';
  }

  String _clean(String value, {String fallback = 'Unknown'}) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  String _parseResolution(String wmSizeOutput) {
    final match = RegExp(r'(\d+)x(\d+)').firstMatch(wmSizeOutput);
    return match == null ? 'Unknown' : '${match.group(1)} x ${match.group(2)}';
  }

  String? _fieldValue(List<String> parts, String fieldName) {
    final String prefix = '$fieldName:';
    for (final String part in parts) {
      if (part.startsWith(prefix)) {
        return part.substring(prefix.length);
      }
    }
    return null;
  }

  DeviceStatus _statusFromAdb(String status) {
    return switch (status) {
      'device' => DeviceStatus.online,
      'offline' => DeviceStatus.offline,
      'unauthorized' => DeviceStatus.unauthorized,
      _ => DeviceStatus.unknown,
    };
  }
}
