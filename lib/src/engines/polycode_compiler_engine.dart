import '../artifacts/execution_artifact.dart';
import '../models/compilation_result.dart';
import '../models/execution_config.dart';
import '../models/execution_request.dart';
import '../models/execution_result.dart';
import 'polycode_engine.dart';

/// Contract for engines that support a separate compilation phase before execution.
abstract interface class PolyCodeCompilerEngine implements PolyCodeEngine {
  /// Compiles source code in [request] into an executable [ExecutionArtifact].
  Future<CompilationResult> compile(ExecutionRequest request);

  /// Executes an already-compiled [artifact] with the specified [config] and optional stdin.
  Future<ExecutionResult> run(
    ExecutionArtifact artifact,
    ExecutionConfig config, {
    String stdin = '',
  });
}
