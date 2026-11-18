import '../../models/diagnostic.dart';

/// Parses standard Clang and GCC compiler output into structured [Diagnostic] objects.
class ClangDiagnosticParser {
  ClangDiagnosticParser._();

  static final RegExp _diagnosticRegex = RegExp(
    r'^(?:(?<file>[^:\n\r]+):)?(?<line>\d+):(?<col>\d+):\s*(?<sev>fatal error|error|warning|info|note):\s*(?<msg>.+)$',
    multiLine: true,
  );

  /// Extracts structured diagnostics from compiler stderr/stdout text.
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
          : (sevStr == 'info' || sevStr == 'note')
              ? DiagnosticSeverity.info
              : DiagnosticSeverity.error;

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

    // Fallback if compiler returned errors but regex didn't match any specific lines
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
