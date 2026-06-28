import '../../domain/storage/storage_service.dart';

/// Local storage stub for the platform foundation.
class LocalStorage implements StorageService {
  /// Stubbed write operation for [key] and [value].
  @override
  Future<void> write(
    String key,
    String value,
  ) async {}

  /// Stubbed read operation for [key].
  @override
  Future<String?> read(
    String key,
  ) async {
    return null;
  }

  /// Stubbed delete operation for [key].
  @override
  Future<void> delete(
    String key,
  ) async {}
}
