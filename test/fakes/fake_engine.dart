import 'dart:async';
import 'dart:typed_data';
import 'package:polycode/polycode.dart';

/// A deterministic fake engine strictly designed for unit tests.
/// Never registered as a production engine.
class FakeEngine implements PolyCodeCompilerEngine {
  FakeEngine({
    this.language = PolyLanguage.python,
    this.simulatedStdout = 'Hello from FakeEngine\n',
    this.simulatedStderr = '',
    this.simulatedExitCode = 0,
    this.executionDelay = Duration.zero,
    this.compilationDelay = Duration.zero,
    this.shouldFailCompilation = false,
    this.shouldFailExecution = false,
  });

  @override
  final PolyLanguage language;

  final String simulatedStdout;
  final String simulatedStderr;
  final int simulatedExitCode;
  final Duration executionDelay;
  final Duration compilationDelay;
  final bool shouldFailCompilation;
  final bool shouldFailExecution;

  bool isDisposed = false;
  int executionCount = 0;
  int compilationCount = 0;

  @override
  Future<EngineCapabilities> getCapabilities() async {
    return const EngineCapabilities(
      supportedModes: {ExecutionMode.interpreted, ExecutionMode.compiled},
      supportsStdin: true,
      supportsStreaming: true,
      supportsCancellation: true,
      supportsMultipleFiles: true,
      version: '0.0.1-fake',
      upstreamEngineName: 'Test Fake Engine',
    );
  }

  @override
  Future<CompilationResult> compile(ExecutionRequest request) async {
    compilationCount++;
    if (compilationDelay > Duration.zero) {
      await Future<void>.delayed(compilationDelay);
    }

    if (shouldFailCompilation) {
      return const CompilationResult(
        isSuccess: false,
        diagnostics: [
          Diagnostic(
            message: 'Simulated compile syntax error',
            severity: DiagnosticSeverity.error,
            line: 1,
            column: 1,
          ),
        ],
        compilerOutput: 'error: failed to compile mock source\n',
      );
    }

    final artifact = ExecutionArtifact(
      id: 'mock-art-${DateTime.now().millisecondsSinceEpoch}',
      language: language,
      bytes: Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]),
    );

    return CompilationResult(
      isSuccess: true,
      artifact: artifact,
      compilerOutput: 'Compilation finished successfully.\n',
    );
  }

  @override
  Future<ExecutionResult> run(
    ExecutionArtifact artifact,
    ExecutionConfig config, {
    String stdin = '',
  }) async {
    return execute(
      ExecutionRequest(
        language: language,
        source: '// artifact',
        stdin: stdin,
        config: config,
      ),
    );
  }

  @override
  Future<ExecutionResult> execute(ExecutionRequest request) async {
    executionCount++;
    if (executionDelay > Duration.zero) {
      await Future<void>.delayed(executionDelay);
    }

    if (shouldFailExecution) {
      throw const PolyCodeException('Simulated execution engine runtime crash');
    }

    final stdoutResult = request.stdin.isNotEmpty
        ? '$simulatedStdout[stdin received: ${request.stdin}]\n'
        : simulatedStdout;

    return ExecutionResult(
      stdout: stdoutResult,
      stderr: simulatedStderr,
      exitCode: simulatedExitCode,
      isSuccess: simulatedExitCode == 0,
      duration: executionDelay,
    );
  }

  @override
  Stream<ExecutionEvent> executeStream(ExecutionRequest request) async* {
    executionCount++;
    yield RunningExecutionEvent();

    if (executionDelay > Duration.zero) {
      await Future<void>.delayed(executionDelay);
    }

    if (shouldFailExecution) {
      yield FailedExecutionEvent(
          const PolyCodeException('Simulated stream crash'));
      return;
    }

    if (simulatedStdout.isNotEmpty) {
      yield StdoutExecutionEvent(simulatedStdout);
    }
    if (request.stdin.isNotEmpty) {
      yield StdoutExecutionEvent('[stdin received: ${request.stdin}]\n');
    }
    if (simulatedStderr.isNotEmpty) {
      yield StderrExecutionEvent(simulatedStderr);
    }

    final result = ExecutionResult(
      stdout: request.stdin.isNotEmpty
          ? '$simulatedStdout[stdin received: ${request.stdin}]\n'
          : simulatedStdout,
      stderr: simulatedStderr,
      exitCode: simulatedExitCode,
      isSuccess: simulatedExitCode == 0,
      duration: executionDelay,
    );

    yield CompletedExecutionEvent(result);
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}
