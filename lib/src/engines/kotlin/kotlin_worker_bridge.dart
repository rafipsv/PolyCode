import '../../artifacts/execution_artifact.dart';
import '../../models/compilation_result.dart';
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import 'kotlin_worker_bridge_stub.dart'
    if (dart.library.html) 'kotlin_worker_bridge_web.dart';

/// Abstract bridge interfacing with the Kotlin compilation and execution runtime.
abstract interface class KotlinWorkerBridge {
  factory KotlinWorkerBridge.create() => createKotlinWorkerBridge();

  /// Compiles source code into a binary or WebAssembly / JVM artifact.
  Future<CompilationResult> compile(ExecutionRequest request);

  /// Streams execution lifecycle events for a compiled artifact or request.
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    ExecutionArtifact? artifact,
  });

  /// Releases resources and cleans temporary files.
  Future<void> dispose();
}
