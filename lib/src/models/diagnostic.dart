import 'package:meta/meta.dart';

/// Severity level of a compiler or linter diagnostic message.
enum DiagnosticSeverity {
  info,
  warning,
  error;
}

/// Normalized diagnostic message from a compiler or static analyzer.
@immutable
class Diagnostic {
  const Diagnostic({
    required this.message,
    this.severity = DiagnosticSeverity.error,
    this.line,
    this.column,
    this.fileName,
    this.code,
  });

  final String message;
  final DiagnosticSeverity severity;
  final int? line;
  final int? column;
  final String? fileName;
  final String? code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Diagnostic &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          severity == other.severity &&
          line == other.line &&
          column == other.column &&
          fileName == other.fileName &&
          code == other.code;

  @override
  int get hashCode => Object.hash(message, severity, line, column, fileName, code);

  @override
  String toString() {
    final loc = line != null ? ' (line: $line${column != null ? ', col: $column' : ''})' : '';
    return '[${severity.name.toUpperCase()}] $message$loc';
  }
}
