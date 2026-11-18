import 'package:meta/meta.dart';
import '../artifacts/execution_artifact.dart';
import 'diagnostic.dart';

/// Normalized result of code execution.
@immutable
class ExecutionResult {
  const ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.exitCode = 0,
    this.isSuccess = true,
    this.isTimedOut = false,
    this.isCancelled = false,
    this.isOutputLimitExceeded = false,
    this.duration = Duration.zero,
    this.isCompiled = false,
    this.diagnostics = const [],
    this.artifact,
    this.error,
  });

  final String stdout;
  final String stderr;
  final int? exitCode;
  final bool isSuccess;
  final bool isTimedOut;
  final bool isCancelled;
  final bool isOutputLimitExceeded;
  final Duration duration;
  final bool isCompiled;
  final List<Diagnostic> diagnostics;
  final ExecutionArtifact? artifact;
  final Object? error;

  bool get hasErrors =>
      stderr.isNotEmpty || (exitCode != null && exitCode != 0) || !isSuccess;

  @override
  String toString() =>
      'ExecutionResult(exitCode: $exitCode, success: $isSuccess, stdout: ${stdout.length} chars, stderr: ${stderr.length} chars, duration: ${duration.inMilliseconds}ms)';
}
