import 'package:meta/meta.dart';
import 'execution_mode.dart';

/// Capabilities and constraints of a registered language engine.
@immutable
class EngineCapabilities {
  const EngineCapabilities({
    required this.supportedModes,
    this.supportsStdin = false,
    this.supportsStreaming = false,
    this.supportsCancellation = false,
    this.supportsMultipleFiles = false,
    this.supportsCompilerOptions = false,
    this.enforcesMemoryLimit = false,
    this.maxExecutionTimeout = const Duration(minutes: 2),
    this.version = '1.0.0',
    this.upstreamEngineName = 'Embedded Engine',
  });

  final Set<ExecutionMode> supportedModes;
  final bool supportsStdin;
  final bool supportsStreaming;
  final bool supportsCancellation;
  final bool supportsMultipleFiles;
  final bool supportsCompilerOptions;
  final bool enforcesMemoryLimit;
  final Duration maxExecutionTimeout;
  final String version;
  final String upstreamEngineName;

  bool get supportsCompilation =>
      supportedModes.contains(ExecutionMode.compiled);

  @override
  String toString() =>
      'EngineCapabilities(modes: $supportedModes, stdin: $supportsStdin, cancel: $supportsCancellation)';
}
