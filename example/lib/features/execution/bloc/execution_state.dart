import 'package:polycode/polycode.dart';

enum ExecutionStatus {
  idle,
  compiling,
  running,
  completed,
  failed,
  cancelled,
}

class ExecutionBlocState {
  const ExecutionBlocState({
    this.status = ExecutionStatus.idle,
    this.stdout = '',
    this.stderr = '',
    this.stdin = '',
    this.exitCode,
    this.duration = Duration.zero,
    this.diagnostics = const [],
    this.errorMessage,
  });

  final ExecutionStatus status;
  final String stdout;
  final String stderr;
  final String stdin;
  final int? exitCode;
  final Duration duration;
  final List<Diagnostic> diagnostics;
  final String? errorMessage;

  bool get isRunning =>
      status == ExecutionStatus.running || status == ExecutionStatus.compiling;

  ExecutionBlocState copyWith({
    ExecutionStatus? status,
    String? stdout,
    String? stderr,
    String? stdin,
    int? exitCode,
    Duration? duration,
    List<Diagnostic>? diagnostics,
    String? errorMessage,
  }) {
    return ExecutionBlocState(
      status: status ?? this.status,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      stdin: stdin ?? this.stdin,
      exitCode: exitCode ?? this.exitCode,
      duration: duration ?? this.duration,
      diagnostics: diagnostics ?? this.diagnostics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
