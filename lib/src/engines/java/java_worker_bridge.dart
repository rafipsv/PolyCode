import '../../artifacts/execution_artifact.dart';
import '../../models/compilation_result.dart';
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import 'java_worker_bridge_stub.dart'
    if (dart.library.html) 'java_worker_bridge_web.dart';

/// Abstract bridge interfacing with the Java compilation and execution runtime.
abstract interface class JavaWorkerBridge {
  factory JavaWorkerBridge.create() => createJavaWorkerBridge();

  /// Compiles source code into a binary or JVM bytecode artifact.
  Future<CompilationResult> compile(ExecutionRequest request);

  /// Streams execution lifecycle events for a compiled artifact or request.
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    ExecutionArtifact? artifact,
  });

  /// Releases resources and cleans temporary files.
  Future<void> dispose();
}
