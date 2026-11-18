import '../../models/diagnostic.dart';

/// Parses standard Go compiler output into structured [Diagnostic] objects.
class GoDiagnosticParser {
  GoDiagnosticParser._();

  static final RegExp _diagnosticRegex = RegExp(
    r'^(?:(?<file>[^:\n\r]+):)?(?<line>\d+):(?<col>\d+):\s*(?<msg>.+)$',
    multiLine: true,
  );

  /// Extracts structured diagnostics from Go compiler error text.
  static List<Diagnostic> parse(String output) {
    if (output.trim().isEmpty) return const [];

    final diagnostics = <Diagnostic>[];
    final matches = _diagnosticRegex.allMatches(output);

    for (final match in matches) {
      final fileName = match.namedGroup('file')?.trim();
      final lineStr = match.namedGroup('line');
      final colStr = match.namedGroup('col');
      final message = match.namedGroup('msg')?.trim() ?? '';

      diagnostics.add(
        Diagnostic(
          message: message,
          severity: DiagnosticSeverity.error,
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
