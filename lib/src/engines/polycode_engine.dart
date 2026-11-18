import '../models/engine_capabilities.dart';
import '../models/execution_event.dart';
import '../models/execution_request.dart';
import '../models/execution_result.dart';
import '../models/poly_language.dart';

/// Base contract for all PolyCode language engines (interpreters and compilers).
abstract interface class PolyCodeEngine {
  /// The primary language supported by this engine.
  PolyLanguage get language;

  /// Returns runtime capabilities supported by this engine.
  Future<EngineCapabilities> getCapabilities();

  /// Executes code synchronously from the request and returns a normalized result.
  Future<ExecutionResult> execute(ExecutionRequest request);

  /// Streams real-time lifecycle events (compiling, stdout, stderr, completion).
  Stream<ExecutionEvent> executeStream(ExecutionRequest request);

  /// Releases resources, kills background workers, or closes ports.
  Future<void> dispose();
}
