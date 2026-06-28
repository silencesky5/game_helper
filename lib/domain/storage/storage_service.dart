/// Defines the contract for key-value platform storage.
abstract class StorageService {
  /// Writes [value] to the provided storage [key].
  Future<void> write(
    String key,
    String value,
  );

  /// Reads the value associated with the provided storage [key].
  Future<String?> read(
    String key,
  );

  /// Deletes the value associated with the provided storage [key].
  Future<void> delete(
    String key,
  );
}
