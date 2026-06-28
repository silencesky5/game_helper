import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/storage/storage_service.dart';

/// SharedPreferences-backed local key/value storage.
class LocalStorage implements StorageService {
  /// Creates local storage with an optional preferences dependency.
  LocalStorage({SharedPreferences? preferences}) : _preferences = preferences;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  /// Writes [value] for [key].
  @override
  Future<void> write(
    String key,
    String value,
  ) async {
    await (await _store).setString(key, value);
  }

  /// Reads the stored value for [key].
  @override
  Future<String?> read(
    String key,
  ) async {
    return (await _store).getString(key);
  }

  /// Deletes the stored value for [key].
  @override
  Future<void> delete(
    String key,
  ) async {
    await (await _store).remove(key);
  }
}
