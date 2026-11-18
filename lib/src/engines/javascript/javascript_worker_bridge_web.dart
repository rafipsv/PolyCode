import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import 'javascript_worker_bridge.dart';
import 'javascript_worker_script.dart';

JavaScriptWorkerBridge createJavaScriptWorkerBridge() =>
    WebJavaScriptWorkerBridge();

/// Web implementation using modern package:web and Web Workers.
class WebJavaScriptWorkerBridge implements JavaScriptWorkerBridge {
  WebJavaScriptWorkerBridge();

  web.Worker? _activeWorker;
  String? _activeObjectUrl;

  @override
  Stream<ExecutionEvent> executeStream(ExecutionRequest request) async* {
    final controller = StreamController<ExecutionEvent>();

    _cleanupActive();

    final blobParts = [kJavaScriptWorkerScript.toJS].toJS;
    final blob = web.Blob(
      blobParts,
      web.BlobPropertyBag(type: 'application/javascript'),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    _activeObjectUrl = objectUrl;

    final worker = web.Worker(objectUrl.toJS);
    _activeWorker = worker;

    final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}';

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
      'source': request.primarySource,
      'stdin': request.stdin,
      'timeoutMs': request.config.timeout.inMilliseconds,
    });
    worker.postMessage(payload.toJS);

    try {
      yield* controller.stream;
    } finally {
      _cleanupActive();
    }
  }

  void _cleanupActive() {
    if (_activeWorker != null) {
      _activeWorker!.terminate();
      _activeWorker = null;
    }
    if (_activeObjectUrl != null) {
      web.URL.revokeObjectURL(_activeObjectUrl!);
      _activeObjectUrl = null;
    }
  }

  @override
  Future<void> dispose() async {
    _cleanupActive();
  }
}
