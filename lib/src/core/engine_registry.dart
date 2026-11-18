import '../engines/polycode_engine.dart';
import '../exceptions/polycode_exception.dart';
import '../models/poly_language.dart';

/// Registry holding active language engines for the runtime.
class EngineRegistry {
  EngineRegistry();

  final Map<PolyLanguage, PolyCodeEngine> _engines = {};

  /// Registered engines mapped by language.
  Map<PolyLanguage, PolyCodeEngine> get engines => Map.unmodifiable(_engines);

  /// Registers an engine. Overwrites any previously registered engine for that language.
  void registerEngine(PolyCodeEngine engine) {
    _engines[engine.language] = engine;
  }

  /// Removes a registered engine for the specified language.
  bool unregisterEngine(PolyLanguage language) {
    return _engines.remove(language) != null;
  }

  /// Retrieves the engine registered for [language], or throws [EngineNotFoundException].
  PolyCodeEngine getEngine(PolyLanguage language) {
    final engine = _engines[language];
    if (engine == null) {
      throw EngineNotFoundException(language);
    }
    return engine;
  }

  /// Checks whether an engine is currently registered for [language].
  bool hasEngine(PolyLanguage language) => _engines.containsKey(language);

  /// Disposes all registered engines.
  Future<void> dispose() async {
    for (final engine in _engines.values) {
      await engine.dispose();
    }
    _engines.clear();
  }
}
