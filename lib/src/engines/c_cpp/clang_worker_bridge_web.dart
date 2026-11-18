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
import 'clang_worker_bridge.dart';
import 'clang_worker_script.dart';

ClangWorkerBridge createClangWorkerBridge() => WebClangWorkerBridge();

/// Web implementation for C and C++ compilation and execution using Web Workers.
class WebClangWorkerBridge implements ClangWorkerBridge {
  WebClangWorkerBridge();

  web.Worker? _activeWorker;
  String? _activeObjectUrl;

  web.Worker _getOrCreateWorker() {
    if (_activeWorker != null) return _activeWorker!;
    final blobParts = [kClangWorkerScript.toJS].toJS;
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
    final reqId = 'c_compile_${DateTime.now().millisecondsSinceEpoch}';

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
                    id: 'wasm_art_${DateTime.now().millisecondsSinceEpoch}',
                    language: request.language,
                    bytes: Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]),
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
        compilerOutput: 'Compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'Compilation timed out.',
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
    final controller = StreamController<ExecutionEvent>();
    final worker = _getOrCreateWorker();
    final reqId = 'c_exec_${DateTime.now().millisecondsSinceEpoch}';

    worker.onmessage = ((web.MessageEvent event) {
      final rawData = event.data;
      final jsonString = rawData.dartify()?.toString();
      if (jsonString != null) {
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          if (data['id'] == reqId) {
            final type = data['type'] as String?;
            if (type == 'STDOUT') {
              controller
                  .add(StdoutExecutionEvent(data['chunk'] as String? ?? ''));
            } else if (type == 'STDERR') {
              controller
                  .add(StderrExecutionEvent(data['chunk'] as String? ?? ''));
            } else if (type == 'COMPLETED') {
              final exitCode = data['exitCode'] as int? ?? 0;
              final durationMs = data['durationMs'] as int? ?? 0;
              final error = data['error'];

              controller.add(
                CompletedExecutionEvent(
                  ExecutionResult(
                    exitCode: exitCode,
                    isSuccess: exitCode == 0,
                    duration: Duration(milliseconds: durationMs),
                    error: error,
                  ),
                ),
              );
              controller.close();
            }
          }
        } catch (_) {}
      }
    }).toJS;

    worker.onerror = ((web.ErrorEvent event) {
      final msg = event.message;
      controller.add(StderrExecutionEvent('Worker Error: $msg\n'));
      controller.add(
        CompletedExecutionEvent(
          ExecutionResult(
            exitCode: 1,
            isSuccess: false,
            error: msg,
          ),
        ),
      );
      controller.close();
    }).toJS;

    final payload = jsonEncode({
      'id': reqId,
      'type': 'EXECUTE',
      'source': request.primarySource,
      'stdin': request.stdin,
      'language': request.language.id,
      'timeoutMs': request.config.timeout.inMilliseconds,
    });
    worker.postMessage(payload.toJS);

    yield* controller.stream;
  }

  @override
  Future<void> dispose() async {
    if (_activeWorker != null) {
      _activeWorker!.terminate();
      _activeWorker = null;
    }
    if (_activeObjectUrl != null) {
      web.URL.revokeObjectURL(_activeObjectUrl!);
      _activeObjectUrl = null;
    }
  }
}
