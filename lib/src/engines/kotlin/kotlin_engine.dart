import '../../artifacts/execution_artifact.dart';
import '../../models/compilation_result.dart';
import '../../models/diagnostic.dart';
import '../../models/engine_capabilities.dart';
import '../../models/execution_config.dart';
import '../../models/execution_event.dart';
import '../../models/execution_mode.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import '../../models/poly_language.dart';
import '../polycode_compiler_engine.dart';
import 'kotlin_diagnostic_parser.dart';
import 'kotlin_worker_bridge.dart';

/// Kotlin compiler and execution engine supporting Kotlin/Wasm and host toolchains.
class KotlinEngine implements PolyCodeCompilerEngine {
  KotlinEngine({KotlinWorkerBridge? bridge})
      : _bridge = bridge ?? KotlinWorkerBridge.create();

  final KotlinWorkerBridge _bridge;

  @override
  PolyLanguage get language => PolyLanguage.kotlin;

  @override
  Future<EngineCapabilities> getCapabilities() async {
    return const EngineCapabilities(
      supportedModes: {ExecutionMode.compiled},
      supportsStdin: true,
      supportsStreaming: true,
      supportsCancellation: true,
      supportsCompilerOptions: true,
      supportsMultipleFiles: true,
      version: 'Kotlin 2.0+ (Kotlin/Wasm & JVM Bytecode)',
      upstreamEngineName: 'Kotlin Multiplatform / Wasm Compiler',
    );
  }

  @override
  Future<CompilationResult> compile(ExecutionRequest request) {
    return _bridge.compile(request);
  }

  @override
  Future<ExecutionResult> run(
    ExecutionArtifact artifact,
    ExecutionConfig config, {
    String stdin = '',
  }) async {
    final req = ExecutionRequest(
      language: language,
      source: '',
      stdin: stdin,
      config: config,
    );
    return _collectResult(executeStream(req, artifact: artifact));
  }

  @override
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    ExecutionArtifact? artifact,
  }) {
    return _bridge.executeStream(request, artifact: artifact);
  }

  @override
  Future<ExecutionResult> execute(ExecutionRequest request) async {
    final comp = await compile(request);
    if (!comp.isSuccess || comp.artifact == null) {
      return ExecutionResult(
        stdout: '',
        stderr: comp.compilerOutput,
        exitCode: 1,
        isSuccess: false,
        duration: comp.duration,
        isCompiled: true,
        diagnostics: comp.diagnostics,
        artifact: comp.artifact,
        error: 'Compilation failed',
      );
    }
    return run(comp.artifact!, request.config, stdin: request.stdin);
  }

  Future<ExecutionResult> _collectResult(Stream<ExecutionEvent> stream) async {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    ExecutionResult? finalResult;
    Object? error;

    await for (final event in stream) {
      if (event is StdoutExecutionEvent) {
        stdoutBuffer.write(event.chunk);
      } else if (event is StderrExecutionEvent) {
        stderrBuffer.write(event.chunk);
      } else if (event is CompletedExecutionEvent) {
        finalResult = event.result;
      } else if (event is FailedExecutionEvent) {
        error = event.error;
      }
    }

    if (finalResult != null) {
      final diags = finalResult.diagnostics.isNotEmpty
          ? finalResult.diagnostics
          : (!finalResult.isSuccess && stderrBuffer.isNotEmpty
              ? KotlinDiagnosticParser.parse(stderrBuffer.toString())
              : const <Diagnostic>[]);
      return ExecutionResult(
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: finalResult.exitCode,
        isSuccess: finalResult.isSuccess,
        duration: finalResult.duration,
        isCompiled: true,
        diagnostics: diags,
        artifact: finalResult.artifact,
        error: finalResult.error,
      );
    }

    return ExecutionResult(
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
      exitCode: 1,
      isSuccess: false,
      isCompiled: true,
      error: error ?? 'Kotlin execution ended without completion result.',
    );
  }

  @override
  Future<void> dispose() => _bridge.dispose();
}
