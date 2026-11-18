import 'package:meta/meta.dart';
import '../artifacts/execution_artifact.dart';
import 'diagnostic.dart';

/// Result of a code compilation phase.
@immutable
class CompilationResult {
  const CompilationResult({
    required this.isSuccess,
    this.diagnostics = const [],
    this.compilerOutput = '',
    this.duration = Duration.zero,
    this.artifact,
    this.engineVersion,
    this.error,
  });

  final bool isSuccess;
  final List<Diagnostic> diagnostics;
  final String compilerOutput;
  final Duration duration;
  final ExecutionArtifact? artifact;
  final String? engineVersion;
  final Object? error;

  List<Diagnostic> get errors =>
      diagnostics.where((d) => d.severity == DiagnosticSeverity.error).toList();

  List<Diagnostic> get warnings => diagnostics
      .where((d) => d.severity == DiagnosticSeverity.warning)
      .toList();

  @override
  String toString() =>
      'CompilationResult(success: $isSuccess, diagnostics: ${diagnostics.length}, duration: ${duration.inMilliseconds}ms)';
}
