import '../../models/diagnostic.dart';

/// Parses standard Dart compiler / analyzer output into structured [Diagnostic] objects.
class DartDiagnosticParser {
  DartDiagnosticParser._();

  static final RegExp _diagnosticRegex = RegExp(
    r'^(?:(?<file>[^:\n\r]+):)?(?<line>\d+):(?<col>\d+):\s*(?<sev>Error|Warning|Info):\s*(?<msg>.+)$',
    multiLine: true,
  );

  /// Extracts structured diagnostics from Dart compiler/analyzer error text.
  static List<Diagnostic> parse(String output) {
    if (output.trim().isEmpty) return const [];

    final diagnostics = <Diagnostic>[];
    final matches = _diagnosticRegex.allMatches(output);

    for (final match in matches) {
      final fileName = match.namedGroup('file')?.trim();
      final lineStr = match.namedGroup('line');
      final colStr = match.namedGroup('col');
      final sevStr = match.namedGroup('sev')?.toLowerCase() ?? 'error';
      final message = match.namedGroup('msg')?.trim() ?? '';

      final severity = (sevStr == 'warning')
          ? DiagnosticSeverity.warning
          : (sevStr == 'info'
              ? DiagnosticSeverity.info
              : DiagnosticSeverity.error);

      diagnostics.add(
        Diagnostic(
          message: message,
          severity: severity,
          line: lineStr != null ? int.tryParse(lineStr) : null,
          column: colStr != null ? int.tryParse(colStr) : null,
          fileName: fileName,
        ),
      );
    }

    if (diagnostics.isEmpty && output.trim().isNotEmpty) {
      diagnostics.add(
        Diagnostic(
          message: output.trim(),
          severity: DiagnosticSeverity.error,
        ),
      );
    }

    return List.unmodifiable(diagnostics);
  }
}
