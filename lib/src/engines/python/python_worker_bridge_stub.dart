import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import 'python_worker_bridge.dart';

PythonWorkerBridge createPythonWorkerBridge() => StubPythonWorkerBridge();

/// Desktop / VM execution bridge using native Python 3 or embedded fallback.
class StubPythonWorkerBridge implements PythonWorkerBridge {
  StubPythonWorkerBridge();

  Process? _activeProcess;

  @override
  Stream<ExecutionEvent> executeStream(ExecutionRequest request) async* {
    final stopwatch = Stopwatch()..start();
    final source = request.primarySource;
    final stdinData = request.stdin;

    final pythonExecutable = _resolvePythonExecutable();

    if (pythonExecutable != null) {
      yield* _executeWithPython3(pythonExecutable, source, stdinData, request.config.timeout);
    } else {
      yield* _executeWithFallbackEvaluator(source, stdinData, stopwatch);
    }
  }

  String? _resolvePythonExecutable() {
    try {
      final res = Process.runSync('which', ['python3']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  Stream<ExecutionEvent> _executeWithPython3(
    String pythonPath,
    String source,
    String stdinData,
    Duration timeout,
  ) async* {
    final controller = StreamController<ExecutionEvent>();
    final stopwatch = Stopwatch()..start();

    Process? process;
    try {
      process = await Process.start(
        pythonPath,
        ['-u', '-c', source],
        mode: ProcessStartMode.normal,
      );
      _activeProcess = process;

      // Pipe stdin if provided
      if (stdinData.isNotEmpty) {
        process.stdin.write(stdinData);
        await process.stdin.flush();
      }
      await process.stdin.close();

      process.stdout.transform(utf8.decoder).listen((chunk) {
        controller.add(StdoutExecutionEvent(chunk));
      });

      process.stderr.transform(utf8.decoder).listen((chunk) {
        controller.add(StderrExecutionEvent(chunk));
      });

      process.exitCode.then((code) {
        stopwatch.stop();
        controller.add(
          CompletedExecutionEvent(
            ExecutionResult(
              exitCode: code,
              isSuccess: code == 0,
              duration: stopwatch.elapsed,
            ),
          ),
        );
        controller.close();
      });

      yield* controller.stream;
    } finally {
      process?.kill();
      _activeProcess = null;
      stopwatch.stop();
    }
  }

  Stream<ExecutionEvent> _executeWithFallbackEvaluator(
    String source,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    final lines = source.split('\n');
    final stdoutBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('print(') && trimmed.endsWith(')')) {
        final inner = trimmed.substring(6, trimmed.length - 1).replaceAll("'", '').replaceAll('"', '');
        stdoutBuffer.writeln(inner);
        yield StdoutExecutionEvent('$inner\n');
      }
    }

    stopwatch.stop();
    yield CompletedExecutionEvent(
      ExecutionResult(
        stdout: stdoutBuffer.toString(),
        exitCode: 0,
        isSuccess: true,
        duration: stopwatch.elapsed,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _activeProcess?.kill();
    _activeProcess = null;
  }
}
