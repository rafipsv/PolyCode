import '../../models/engine_capabilities.dart';
import '../../models/execution_event.dart';
import '../../models/execution_mode.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import '../../models/poly_language.dart';
import '../polycode_engine.dart';
import 'javascript_worker_bridge.dart';

/// Production-ready local JavaScript engine running in an isolated Web Worker.
class JavaScriptEngine implements PolyCodeEngine {
  JavaScriptEngine({JavaScriptWorkerBridge? bridge})
      : _bridge = bridge ?? JavaScriptWorkerBridge.create();

  final JavaScriptWorkerBridge _bridge;

  @override
  PolyLanguage get language => PolyLanguage.javascript;

  @override
  Future<EngineCapabilities> getCapabilities() async {
    return const EngineCapabilities(
      supportedModes: {ExecutionMode.interpreted},
      supportsStdin: true,
      supportsStreaming: true,
      supportsCancellation: true,
      supportsMultipleFiles: false,
      version: 'ES2022 (Isolated Web Worker)',
      upstreamEngineName: 'Browser JavaScript Engine',
    );
  }

  @override
  Stream<ExecutionEvent> executeStream(ExecutionRequest request) {
    return _bridge.executeStream(request);
  }

  @override
  Future<ExecutionResult> execute(ExecutionRequest request) async {
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    ExecutionResult? finalResult;
    Object? error;

    await for (final event in executeStream(request)) {
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
      return ExecutionResult(
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: finalResult.exitCode,
        isSuccess: finalResult.isSuccess,
        duration: finalResult.duration,
        error: finalResult.error,
      );
    }

    return ExecutionResult(
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
      exitCode: 1,
      isSuccess: false,
      error: error ?? 'Execution finished without a completion result.',
    );
  }

  @override
  Future<void> dispose() async {
    await _bridge.dispose();
  }
}
