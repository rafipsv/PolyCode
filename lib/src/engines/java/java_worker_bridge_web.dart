import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../../artifacts/execution_artifact.dart';
import '../../models/compilation_result.dart';
import '../../models/diagnostic.dart';
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import 'java_worker_bridge.dart';
import 'java_worker_script.dart';

JavaWorkerBridge createJavaWorkerBridge() => WebJavaWorkerBridge();

/// Web implementation for Java compilation and execution using Web Workers.
class WebJavaWorkerBridge implements JavaWorkerBridge {
  WebJavaWorkerBridge();

  web.Worker? _activeWorker;
  String? _activeObjectUrl;

  web.Worker _getOrCreateWorker() {
    if (_activeWorker != null) return _activeWorker!;
    final blobParts = [kJavaWorkerScript.toJS].toJS;
    final blob = web.Blob(
      blobParts,
      web.BlobPropertyBag(type: 'application/javascript'),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    _activeObjectUrl = objectUrl;
    _activeWorker = web.Worker(objectUrl.toJS);
    return _activeWorker!;
  }

  @override
  Future<CompilationResult> compile(ExecutionRequest request) async {
    final worker = _getOrCreateWorker();
    final completer = Completer<CompilationResult>();
    final reqId = 'java_compile_${DateTime.now().millisecondsSinceEpoch}';

    worker.onmessage = ((web.MessageEvent event) {
      final rawData = event.data;
      final jsonString = rawData.dartify()?.toString();
      if (jsonString != null) {
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          if (data['id'] == reqId && data['type'] == 'COMPILATION_RESULT') {
            final isSuccess = data['isSuccess'] as bool? ?? false;
            final output = data['compilerOutput'] as String? ?? '';
            final rawDiags = data['diagnostics'] as List? ?? [];

            final diagnostics = rawDiags.map((d) {
              final m = d as Map<String, dynamic>;
              final sevStr = m['severity'] as String? ?? 'error';
              return Diagnostic(
                message: m['message'] as String? ?? '',
                severity: sevStr == 'warning'
                    ? DiagnosticSeverity.warning
                    : DiagnosticSeverity.error,
                line: m['line'] as int?,
                column: m['column'] as int?,
              );
            }).toList();

            final artifact = isSuccess
                ? ExecutionArtifact(
                    id: 'java_class_${DateTime.now().millisecondsSinceEpoch}',
                    language: request.language,
                    bytes: Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE]),
                  )
                : null;

            if (!completer.isCompleted) {
              completer.complete(
                CompilationResult(
                  isSuccess: isSuccess,
                  compilerOutput: output,
                  diagnostics: diagnostics,
                  artifact: artifact,
                ),
              );
            }
          }
        } catch (_) {}
      }
    }).toJS;

    final payload = jsonEncode({
      'id': reqId,
      'type': 'COMPILE',
      'source': request.primarySource,
      'language': request.language.id,
    });
    worker.postMessage(payload.toJS);

    return completer.future.timeout(
      request.config.timeout,
      onTimeout: () => const CompilationResult(
        isSuccess: false,
        compilerOutput: 'Java compilation timed out in Web Worker.\n',
        diagnostics: [
          Diagnostic(
            message: 'Compilation timed out',
            severity: DiagnosticSeverity.error,
          ),
        ],
      ),
    );
  }

  @override
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    ExecutionArtifact? artifact,
  }) async* {
    final worker = _getOrCreateWorker();
    final controller = StreamController<ExecutionEvent>();
    final reqId = 'java_exec_${DateTime.now().millisecondsSinceEpoch}';

    worker.onmessage = ((web.MessageEvent event) {
      final rawData = event.data;
      final jsonString = rawData.dartify()?.toString();
      if (jsonString != null) {
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          if (data['id'] != reqId) return;

          final type = data['type'] as String?;
          if (type == 'STDOUT') {
            final text = (data['chunk'] ?? data['data'] ?? '') as String;
            controller.add(StdoutExecutionEvent(text));
          } else if (type == 'STDERR') {
            final text = (data['chunk'] ?? data['data'] ?? '') as String;
            controller.add(StderrExecutionEvent(text));
          } else if (type == 'EXECUTION_COMPLETE' || type == 'COMPLETED') {
            final exitCode = data['exitCode'] as int? ?? 0;
            final durationMs = (data['durationMs'] as num?)?.toInt() ?? 0;
            controller.add(
              CompletedExecutionEvent(
                ExecutionResult(
                  exitCode: exitCode,
                  isSuccess: exitCode == 0,
                  duration: Duration(milliseconds: durationMs),
                ),
              ),
            );
            controller.close();
          } else if (type == 'EXECUTION_FAILED') {
            final err = data['error'] as String? ?? 'Execution failed';
            controller.add(FailedExecutionEvent(Exception(err)));
            controller.close();
          }
        } catch (e) {
          controller.add(
              FailedExecutionEvent(Exception('Malformed worker response: $e')));
          controller.close();
        }
      }
    }).toJS;

    final payload = jsonEncode({
      'id': reqId,
      'type': 'EXECUTE',
      'source': request.primarySource,
      'stdin': request.stdin,
      'language': request.language.id,
    });
    worker.postMessage(payload.toJS);

    yield* controller.stream;
  }

  @override
  Future<void> dispose() async {
    _activeWorker?.terminate();
    _activeWorker = null;
    if (_activeObjectUrl != null) {
      web.URL.revokeObjectURL(_activeObjectUrl!);
      _activeObjectUrl = null;
    }
  }
}
