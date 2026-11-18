import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import 'javascript_worker_bridge_stub.dart'
    if (dart.library.html) 'javascript_worker_bridge_web.dart';

/// Abstract bridge interfacing with the JavaScript execution worker.
abstract interface class JavaScriptWorkerBridge {
  factory JavaScriptWorkerBridge.create() => createJavaScriptWorkerBridge();

  /// Streams execution lifecycle events from the worker.
  Stream<ExecutionEvent> executeStream(ExecutionRequest request);

  /// Disposes workers and cleans up active resources.
  Future<void> dispose();
}
