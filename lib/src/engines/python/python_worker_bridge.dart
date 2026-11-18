import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import 'python_worker_bridge_stub.dart'
    if (dart.library.html) 'python_worker_bridge_web.dart';

/// Abstract bridge interfacing with the Python execution runtime.
abstract interface class PythonWorkerBridge {
  factory PythonWorkerBridge.create() => createPythonWorkerBridge();

  /// Streams execution lifecycle events from the worker.
  Stream<ExecutionEvent> executeStream(ExecutionRequest request);

  /// Disposes workers and cleans up active resources.
  Future<void> dispose();
}
