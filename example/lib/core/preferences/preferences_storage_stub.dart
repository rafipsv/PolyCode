import 'preferences_storage.dart';

PreferencesStorage createDefaultPreferencesStorage() =>
    InMemoryPreferencesStorage();

/// In-memory implementation of [PreferencesStorage] used for tests and non-web platforms.
class InMemoryPreferencesStorage implements PreferencesStorage {
  final Map<String, Object> _store = {};

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;

  @override
  Future<bool?> getBool(String key) async => _store[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  Future<double?> getDouble(String key) async => _store[key] as double?;

  @override
  Future<void> setDouble(String key, double value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<void> clear() async => _store.clear();
}
