import '../models/execution_mode.dart';
import '../models/language_info.dart';
import '../models/language_status.dart';
import '../models/poly_language.dart';
import '../models/poly_platform.dart';

/// Central registry managing supported language definitions and metadata.
class LanguageRegistry {
  LanguageRegistry({PolyPlatform? platform})
      : _platform = platform ?? PolyPlatform.current {
    _initDefaultDefinitions();
  }

  final PolyPlatform _platform;
  final Map<PolyLanguage, LanguageInfo> _languages = {};

  PolyPlatform get platform => _platform;

  /// Returns unmodifiable mapping of all registered language metadata.
  Map<PolyLanguage, LanguageInfo> get allLanguages => Map.unmodifiable(_languages);

  /// Returns list of languages runnable on the current platform.
  List<PolyLanguage> get runnableLanguages => _languages.entries
      .where((e) => e.value.isRunnable)
      .map((e) => e.key)
      .toList(growable: false);

  /// Retrieves metadata for a specific language.
  LanguageInfo? getInfo(PolyLanguage language) => _languages[language];

  /// Updates or overrides metadata for a specific language (e.g., when an engine is registered).
  void registerLanguage(LanguageInfo info) {
    _languages[info.language] = info;
  }

  /// Sets status of a language dynamically based on engine discovery.
  void setStatus(PolyLanguage language, LanguageStatus status, {String? reason}) {
    final existing = _languages[language];
    if (existing != null) {
      _languages[language] = existing.copyWith(
        status: status,
        statusReason: reason,
      );
    }
  }

  void _initDefaultDefinitions() {
    // Honest initial default definitions for all 9 target languages.
    // In Phase 0-1, real WebAssembly/native runtimes are planned/staged.
    _languages[PolyLanguage.javascript] = const LanguageInfo(
      language: PolyLanguage.javascript,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.interpreted},
      runtimeName: 'QuickJS (WASM)',
      statusReason: 'Targeted for Phase 2 browser integration.',
    );

    _languages[PolyLanguage.python] = const LanguageInfo(
      language: PolyLanguage.python,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.interpreted},
      runtimeName: 'CPython / MicroPython (WASM)',
      statusReason: 'Targeted for Phase 3 browser integration.',
    );

    _languages[PolyLanguage.c] = const LanguageInfo(
      language: PolyLanguage.c,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.compiled},
      runtimeName: 'Clang/LLVM (WASM)',
      statusReason: 'Targeted for Phase 4 browser integration.',
    );

    _languages[PolyLanguage.cpp] = const LanguageInfo(
      language: PolyLanguage.cpp,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.compiled},
      runtimeName: 'Clang/LLVM (WASM)',
      statusReason: 'Targeted for Phase 4 browser integration.',
    );

    _languages[PolyLanguage.rust] = const LanguageInfo(
      language: PolyLanguage.rust,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.compiled},
      runtimeName: 'Rust wasm32 toolchain',
      statusReason: 'Targeted for Phase 8 browser integration.',
    );

    _languages[PolyLanguage.go] = const LanguageInfo(
      language: PolyLanguage.go,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.compiled},
      runtimeName: 'Go WebAssembly (WASI/js)',
      statusReason: 'Targeted for Phase 8 browser integration.',
    );

    _languages[PolyLanguage.java] = const LanguageInfo(
      language: PolyLanguage.java,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.compiled, ExecutionMode.interpreted},
      runtimeName: 'JVM/WASM Runtime',
      statusReason: 'Targeted for Phase 9 feasibility spike.',
    );

    _languages[PolyLanguage.kotlin] = const LanguageInfo(
      language: PolyLanguage.kotlin,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.compiled},
      runtimeName: 'Kotlin toolchain',
      statusReason: 'Targeted for Phase 9 feasibility spike.',
    );

    _languages[PolyLanguage.dart] = const LanguageInfo(
      language: PolyLanguage.dart,
      status: LanguageStatus.planned,
      supportedModes: {ExecutionMode.interpreted, ExecutionMode.jitted},
      runtimeName: 'Dart standalone runtime',
      statusReason: 'Targeted for Phase 10 feasibility spike.',
    );
  }
}
