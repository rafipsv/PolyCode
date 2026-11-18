import 'package:meta/meta.dart';
import 'compilation_result.dart';
import 'execution_result.dart';

/// Base class for all lifecycle events during code execution.
@immutable
sealed class ExecutionEvent {
  const ExecutionEvent(this.timestamp);
  final DateTime timestamp;
}

class QueuedExecutionEvent extends ExecutionEvent {
  QueuedExecutionEvent([DateTime? time]) : super(time ?? DateTime.now());
}

class PreparingExecutionEvent extends ExecutionEvent {
  PreparingExecutionEvent({this.message, DateTime? time})
      : super(time ?? DateTime.now());
  final String? message;
}

class CompilingExecutionEvent extends ExecutionEvent {
  CompilingExecutionEvent([DateTime? time]) : super(time ?? DateTime.now());
}

class RunningExecutionEvent extends ExecutionEvent {
  RunningExecutionEvent([DateTime? time]) : super(time ?? DateTime.now());
}

class StdoutExecutionEvent extends ExecutionEvent {
  StdoutExecutionEvent(this.chunk, [DateTime? time])
      : super(time ?? DateTime.now());
  final String chunk;
}

class StderrExecutionEvent extends ExecutionEvent {
  StderrExecutionEvent(this.chunk, [DateTime? time])
      : super(time ?? DateTime.now());
  final String chunk;
}

class CompletedExecutionEvent extends ExecutionEvent {
  CompletedExecutionEvent(this.result, [DateTime? time])
      : super(time ?? DateTime.now());
  final ExecutionResult result;
}

class FailedExecutionEvent extends ExecutionEvent {
  FailedExecutionEvent(this.error, {this.compilationResult, DateTime? time})
      : super(time ?? DateTime.now());
  final Object error;
  final CompilationResult? compilationResult;
}

class CancelledExecutionEvent extends ExecutionEvent {
  CancelledExecutionEvent([DateTime? time]) : super(time ?? DateTime.now());
}
