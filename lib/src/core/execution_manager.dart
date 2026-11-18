import 'dart:async';
import '../engines/polycode_compiler_engine.dart';
import '../exceptions/polycode_exception.dart';
import '../models/compilation_result.dart';
import '../models/execution_event.dart';
import '../models/execution_request.dart';
import '../models/execution_result.dart';
import '../utils/cancellation_token.dart';
import '../utils/stream_bounded_buffer.dart';
import 'engine_registry.dart';
import 'language_registry.dart';

/// Central coordinator for compiling and executing code safely.
class ExecutionManager {
  ExecutionManager({
    required this.engineRegistry,
    required this.languageRegistry,
  });

  final EngineRegistry engineRegistry;
  final LanguageRegistry languageRegistry;

  /// Executes code synchronously and returns normalized [ExecutionResult].
  Future<ExecutionResult> execute(
    ExecutionRequest request, {
    CancellationToken? cancelToken,
  }) async {
    final stream = executeStream(request, cancelToken: cancelToken);
    ExecutionResult? finalResult;
    Object? capturedError;

    await for (final event in stream) {
      if (event is CompletedExecutionEvent) {
        finalResult = event.result;
      } else if (event is FailedExecutionEvent) {
        capturedError = event.error;
      }
    }

    if (finalResult != null) {
      return finalResult;
    }

    if (capturedError != null) {
      if (capturedError is PolyCodeException) {
        throw capturedError;
      }
      throw PolyCodeException(capturedError.toString());
    }

    throw const PolyCodeException('Execution ended unexpectedly without a result.');
  }

  /// Streams lifecycle events for execution with timeout and cancellation enforcement.
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    CancellationToken? cancelToken,
  }) async* {
    yield QueuedExecutionEvent();

    if (cancelToken != null && cancelToken.isCancelled) {
      yield CancelledExecutionEvent();
      return;
    }

    final engine = engineRegistry.getEngine(request.language);
    final stopwatch = Stopwatch()..start();

    final stdoutBuffer = StreamBoundedBuffer(maxBytes: request.config.maxOutputBytes);
    final stderrBuffer = StreamBoundedBuffer(maxBytes: request.config.maxOutputBytes);

    yield PreparingExecutionEvent(message: 'Initializing ${request.language.displayName} engine');

    // Compilation phase if applicable
    CompilationResult? compilationResult;
    if (engine is PolyCodeCompilerEngine) {
      yield CompilingExecutionEvent();
      try {
        compilationResult = await engine.compile(request).timeout(request.config.timeout);
        if (!compilationResult.isSuccess) {
          stopwatch.stop();
          final error = CompilationException(
            message: 'Compilation failed for ${request.language.displayName}',
            compilationResult: compilationResult,
          );
          yield FailedExecutionEvent(error, compilationResult: compilationResult);
          return;
        }
      } on TimeoutException {
        stopwatch.stop();
        yield FailedExecutionEvent(ExecutionTimeoutException(request.config.timeout));
        return;
      } catch (e) {
        stopwatch.stop();
        yield FailedExecutionEvent(
          e is PolyCodeException ? e : PolyCodeException('Compiler error: $e'),
        );
        return;
      }
    }

    yield RunningExecutionEvent();

    ExecutionResult? engineFinalResult;
    Object? engineError;

    try {
      final engineStream = _wrapWithCancellation(
        engine.executeStream(request),
        cancelToken,
      );

      await for (final event in engineStream.timeout(request.config.timeout)) {
        if (cancelToken != null && cancelToken.isCancelled) {
          yield CancelledExecutionEvent();
          return;
        }

        if (event is CancelledExecutionEvent) {
          yield event;
          return;
        } else if (event is StdoutExecutionEvent) {
          stdoutBuffer.append(event.chunk);
          yield event;
        } else if (event is StderrExecutionEvent) {
          stderrBuffer.append(event.chunk);
          yield event;
        } else if (event is CompletedExecutionEvent) {
          engineFinalResult = event.result;
        } else if (event is FailedExecutionEvent) {
          engineError = event.error;
          yield event;
          return;
        } else {
          yield event;
        }
      }
    } on TimeoutException {
      stopwatch.stop();
      yield FailedExecutionEvent(ExecutionTimeoutException(request.config.timeout));
      return;
    } catch (e) {
      stopwatch.stop();
      yield FailedExecutionEvent(
        e is PolyCodeException ? e : PolyCodeException(e.toString()),
      );
      return;
    } finally {
      stopwatch.stop();
    }

    if (cancelToken != null && cancelToken.isCancelled) {
      yield CancelledExecutionEvent();
      return;
    }

    if (engineError != null) {
      return;
    }

    final normalizedResult = ExecutionResult(
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
      exitCode: engineFinalResult?.exitCode ?? 0,
      isSuccess: (engineFinalResult?.isSuccess ?? true) &&
          !stdoutBuffer.isExceeded &&
          !stderrBuffer.isExceeded,
      isTimedOut: engineFinalResult?.isTimedOut ?? false,
      isCancelled: engineFinalResult?.isCancelled ?? false,
      isOutputLimitExceeded: stdoutBuffer.isExceeded || stderrBuffer.isExceeded,
      duration: stopwatch.elapsed,
      isCompiled: engine is PolyCodeCompilerEngine,
      diagnostics: compilationResult?.diagnostics ??
          engineFinalResult?.diagnostics ??
          const [],
      artifact: compilationResult?.artifact ?? engineFinalResult?.artifact,
      error: engineFinalResult?.error,
    );

    yield CompletedExecutionEvent(normalizedResult);
  }

  /// Wraps a stream to interrupt when the cancellation token is triggered.
  Stream<ExecutionEvent> _wrapWithCancellation(
    Stream<ExecutionEvent> stream,
    CancellationToken? cancelToken,
  ) {
    if (cancelToken == null) return stream;

    final controller = StreamController<ExecutionEvent>();
    late final StreamSubscription<ExecutionEvent> sub;

    void onCancel() {
      if (!controller.isClosed) {
        controller.add(CancelledExecutionEvent());
        sub.cancel();
        controller.close();
      }
    }

    cancelToken.onCancel(onCancel);

    sub = stream.listen(
      (event) {
        if (!controller.isClosed) {
          controller.add(event);
        }
      },
      onError: (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return controller.stream;
  }

  /// Compiles code without running if the engine supports compilation.
  Future<CompilationResult> compile(ExecutionRequest request) async {
    final engine = engineRegistry.getEngine(request.language);
    if (engine is PolyCodeCompilerEngine) {
      return engine.compile(request).timeout(request.config.timeout);
    }
    throw UnsupportedLanguageException(
      request.language,
      'Engine does not support a separate compilation step.',
    );
  }
}
