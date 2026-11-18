import 'package:meta/meta.dart';

/// Configuration options controlling a single execution lifecycle.
@immutable
class ExecutionConfig {
  const ExecutionConfig({
    this.timeout = const Duration(seconds: 15),
    this.maxOutputBytes = 256 * 1024, // 256 KB
    this.memoryLimitMb = 128,
    this.args = const [],
    this.compilerOptions = const [],
    this.cleanWorkspaceAfterRun = true,
  });

  final Duration timeout;
  final int maxOutputBytes;
  final int memoryLimitMb;
  final List<String> args;
  final List<String> compilerOptions;
  final bool cleanWorkspaceAfterRun;

  ExecutionConfig copyWith({
    Duration? timeout,
    int? maxOutputBytes,
    int? memoryLimitMb,
    List<String>? args,
    List<String>? compilerOptions,
    bool? cleanWorkspaceAfterRun,
  }) {
    return ExecutionConfig(
      timeout: timeout ?? this.timeout,
      maxOutputBytes: maxOutputBytes ?? this.maxOutputBytes,
      memoryLimitMb: memoryLimitMb ?? this.memoryLimitMb,
      args: args ?? this.args,
      compilerOptions: compilerOptions ?? this.compilerOptions,
      cleanWorkspaceAfterRun:
          cleanWorkspaceAfterRun ?? this.cleanWorkspaceAfterRun,
    );
  }

  @override
  String toString() =>
      'ExecutionConfig(timeout: ${timeout.inSeconds}s, maxBytes: $maxOutputBytes, mem: ${memoryLimitMb}MB)';
}
