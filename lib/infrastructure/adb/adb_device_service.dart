import 'dart:io';

import '../../domain/device/device.dart';
import '../../domain/device/device_service.dart';
import 'adb_command_runner.dart';
import 'adb_device.dart';

/// ADB-backed device service for Android emulator discovery.
class AdbDeviceService implements DeviceService {
  /// Creates an ADB-backed device service.
  const AdbDeviceService({this.commandRunner = const AdbCommandRunner()});

  /// Runner responsible for invoking adb.
  final AdbCommandRunner commandRunner;

  @override
  Future<List<Device>> detectDevices() async {
    try {
      final ProcessResult result = await commandRunner.run(<String>['devices', '-l']);
      if (result.exitCode != 0) {
        return const <Device>[];
      }
      return _parseDevices(result.stdout.toString());
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
    await commandRunner.run(<String>['disconnect', deviceId]);
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

  List<Device> _parseDevices(String output) {
    return output
        .split('\n')
        .skip(1)
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
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
