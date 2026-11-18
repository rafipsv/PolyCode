import 'package:web/web.dart' as web;
import 'preferences_storage.dart';

PreferencesStorage createDefaultPreferencesStorage() => WebPreferencesStorage();

/// Web implementation of [PreferencesStorage] using HTML5 localStorage.
class WebPreferencesStorage implements PreferencesStorage {
  @override
  Future<String?> getString(String key) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final val = web.window.localStorage.getItem(key);
    if (val == null) return null;
    return val == 'true';
  }

  @override
  Future<void> setBool(String key, bool value) async {
    web.window.localStorage.setItem(key, value.toString());
  }

  @override
  Future<double?> getDouble(String key) async {
    final val = web.window.localStorage.getItem(key);
    if (val == null) return null;
    return double.tryParse(val);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    web.window.localStorage.setItem(key, value.toString());
  }

  @override
  Future<void> remove(String key) async {
    web.window.localStorage.removeItem(key);
  }

  @override
  Future<void> clear() async {
    web.window.localStorage.clear();
  }
}
