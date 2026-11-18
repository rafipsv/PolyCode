import 'preferences_storage_stub.dart'
    if (dart.library.js_interop) 'preferences_storage_web.dart';

/// Contract for persistent user preferences in the playground.
abstract class PreferencesStorage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);
  Future<void> remove(String key);
  Future<void> clear();

  static PreferencesStorage? _instance;

  /// Default singleton storage instance (localStorage on Web, in-memory on VM/tests).
  static PreferencesStorage get instance {
    return _instance ??= createDefaultPreferencesStorage();
  }

  /// Sets a custom or mock storage instance (useful for unit tests).
  static void setMockInstance(PreferencesStorage? storage) {
    _instance = storage;
  }
}
