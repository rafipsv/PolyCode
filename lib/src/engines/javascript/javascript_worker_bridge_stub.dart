import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import 'javascript_worker_bridge.dart';

JavaScriptWorkerBridge createJavaScriptWorkerBridge() =>
    StubJavaScriptWorkerBridge();

/// Desktop / VM execution bridge using local Node.js or embedded fallback.
class StubJavaScriptWorkerBridge implements JavaScriptWorkerBridge {
  StubJavaScriptWorkerBridge();

  Process? _activeProcess;

  @override
  Stream<ExecutionEvent> executeStream(ExecutionRequest request) async* {
    final stopwatch = Stopwatch()..start();
    final source = request.primarySource;
    final stdinData = request.stdin;

    // Check if node is available in PATH
    final nodeExecutable = _resolveNodeExecutable();

    if (nodeExecutable != null) {
      yield* _executeWithNode(
          nodeExecutable, source, stdinData, request.config.timeout);
    } else {
      yield* _executeWithBasicEvaluator(source, stdinData, stopwatch);
    }
  }

  String? _resolveNodeExecutable() {
    try {
      final res = Process.runSync('which', ['node']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  Stream<ExecutionEvent> _executeWithNode(
    String nodePath,
    String source,
    String stdinData,
    Duration timeout,
  ) async* {
    final controller = StreamController<ExecutionEvent>();
    final stopwatch = Stopwatch()..start();

    // Node script wrapping user code with identical console and stdin semantics
    final nodeWrapper = '''
const readline = require('readline');
const fs = require('fs');

let stdinLines = ${jsonEncode(stdinData)}.split('\\n');
let stdinCursor = 0;
function customReadline() {
  if (stdinCursor < stdinLines.length) {
    return stdinLines[stdinCursor++];
  }
  return null;
}

try {
  const runner = new Function('console', 'print', 'readline', 'input', '"use strict";\\n' + ${jsonEncode(source)});
  const res = runner(console, console.log, customReadline, customReadline);
  if (res instanceof Promise) {
    res.then(() => process.exit(0)).catch(err => {
      console.error(err && err.stack ? err.stack : String(err));
      process.exit(1);
    });
  } else {
    process.exit(0);
  }
} catch (err) {
  console.error(err && err.stack ? err.stack : String(err));
  process.exit(1);
}
''';

    Process? process;
    try {
      process = await Process.start(nodePath, ['-e', nodeWrapper]);
      _activeProcess = process;

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

  Stream<ExecutionEvent> _executeWithBasicEvaluator(
    String source,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    // Pure Dart minimal fallback evaluator for environments without node
    final lines = source.split('\n');
    final stdoutBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('console.log(') || trimmed.startsWith('print(')) {
        final startIdx = trimmed.indexOf('(');
        final endIdx = trimmed.lastIndexOf(')');
        if (startIdx != -1 && endIdx > startIdx) {
          final content = trimmed
              .substring(startIdx + 1, endIdx)
              .replaceAll("'", '')
              .replaceAll('"', '');
          stdoutBuffer.writeln(content);
          yield StdoutExecutionEvent('$content\n');
        }
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
