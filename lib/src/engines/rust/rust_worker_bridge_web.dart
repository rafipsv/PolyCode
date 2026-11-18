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
import 'rust_worker_bridge.dart';
import 'rust_worker_script.dart';

RustWorkerBridge createRustWorkerBridge() => WebRustWorkerBridge();

/// Web implementation for Rust compilation and execution using Web Workers.
class WebRustWorkerBridge implements RustWorkerBridge {
  WebRustWorkerBridge();

  web.Worker? _activeWorker;
  String? _activeObjectUrl;
  final Map<String, String> _cachedSources = {};

  web.Worker _getOrCreateWorker() {
    if (_activeWorker != null) return _activeWorker!;
    final blobParts = [kRustWorkerScript.toJS].toJS;
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
    final reqId = 'rust_compile_${DateTime.now().millisecondsSinceEpoch}';

    worker.onmessage = ((web.MessageEvent event) {
      final rawData = event.data;
      final dartData = rawData.dartify();
      Map<String, dynamic>? data;
      if (dartData is String) {
        try {
          data = jsonDecode(dartData) as Map<String, dynamic>;
        } catch (_) {}
      } else if (dartData is Map) {
        data = dartData.map((k, v) => MapEntry(k.toString(), v));
      }

      if (data != null) {
        try {
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

            final artifactId =
                'rust_wasm_${DateTime.now().millisecondsSinceEpoch}';
            if (isSuccess) {
              _cachedSources[artifactId] = request.primarySource;
            }

            final artifact = isSuccess
                ? ExecutionArtifact(
                    id: artifactId,
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
        compilerOutput: 'Rust compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'rustc compilation timed out.',
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
    final reqId = 'rust_exec_${DateTime.now().millisecondsSinceEpoch}';

    var source = request.primarySource;
    if (source.isEmpty &&
        artifact != null &&
        _cachedSources.containsKey(artifact.id)) {
      source = _cachedSources[artifact.id]!;
    }

    worker.onmessage = ((web.MessageEvent event) {
      final rawData = event.data;
      final dartData = rawData.dartify();
      Map<String, dynamic>? data;
      if (dartData is String) {
        try {
          data = jsonDecode(dartData) as Map<String, dynamic>;
        } catch (_) {}
      } else if (dartData is Map) {
        data = dartData.map((k, v) => MapEntry(k.toString(), v));
      }

      if (data != null) {
        try {
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
      'source': source,
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
