import '../engines/c_cpp/c_engine.dart';
import '../engines/c_cpp/cpp_engine.dart';
import '../engines/javascript/javascript_engine.dart';
import '../engines/polycode_engine.dart';
import '../engines/python/python_engine.dart';
import '../models/compilation_result.dart';
import '../models/execution_event.dart';
import '../models/execution_request.dart';
import '../models/execution_result.dart';
import '../models/language_info.dart';
import '../models/language_status.dart';
import '../models/platform_capabilities.dart';
import '../models/poly_language.dart';
import '../models/poly_platform.dart';
import '../utils/cancellation_token.dart';
import 'engine_registry.dart';
import 'execution_manager.dart';
import 'language_registry.dart';
import 'polycode_config.dart';

/// Main public facade for the PolyCode compiler and execution SDK.
class PolyCode {
  PolyCode({
    PolyCodeConfig? config,
    PolyPlatform? platform,
    bool autoRegisterDefaults = true,
  })  : config = config ?? const PolyCodeConfig(),
        platform = platform ?? PolyPlatform.current {
    languageRegistry = LanguageRegistry(platform: this.platform);
    engineRegistry = EngineRegistry();
    executionManager = ExecutionManager(
      engineRegistry: engineRegistry,
      languageRegistry: languageRegistry,
    );
    if (autoRegisterDefaults) {
      registerEngine(JavaScriptEngine());
      registerEngine(PythonEngine());
      registerEngine(CEngine());
      registerEngine(CppEngine());
    }
  }

  final PolyCodeConfig config;
  final PolyPlatform platform;
  late final LanguageRegistry languageRegistry;
  late final EngineRegistry engineRegistry;
  late final ExecutionManager executionManager;

  /// Registers an execution engine and marks the language as available.
  void registerEngine(PolyCodeEngine engine) {
    engineRegistry.registerEngine(engine);
    languageRegistry.setStatus(
      engine.language,
      LanguageStatus.available,
      reason: 'Registered engine: ${engine.runtimeType}',
    );
  }

  /// Removes an engine registration and marks language as planned or unsupported.
  void unregisterEngine(PolyLanguage language) {
    engineRegistry.unregisterEngine(language);
    languageRegistry.setStatus(
      language,
      LanguageStatus.planned,
      reason: 'Engine unregistered',
    );
  }

  /// Checks if an engine is registered for [language].
  bool isEngineAvailable(PolyLanguage language) =>
      engineRegistry.hasEngine(language);

  /// Retrieves platform-wide execution capabilities and status.
  PlatformCapabilities getPlatformCapabilities() {
    return PlatformCapabilities(
      platform: platform,
      languages: languageRegistry.allLanguages,
    );
  }

  /// Retrieves metadata for a specific language.
  LanguageInfo? getLanguageInfo(PolyLanguage language) =>
      languageRegistry.getInfo(language);

  /// Executes code from [request] and returns a normalized [ExecutionResult].
  Future<ExecutionResult> execute(
    ExecutionRequest request, {
    CancellationToken? cancelToken,
  }) {
    return executionManager.execute(request, cancelToken: cancelToken);
  }

  /// Streams real-time lifecycle events (compiling, stdout, stderr, finish).
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    CancellationToken? cancelToken,
  }) {
    return executionManager.executeStream(request, cancelToken: cancelToken);
  }

  /// Compiles code without running it for compiled languages.
  Future<CompilationResult> compile(ExecutionRequest request) {
    return executionManager.compile(request);
  }

  /// Disposes all registered engines and releases background workers.
  Future<void> dispose() async {
    await engineRegistry.dispose();
  }
}
