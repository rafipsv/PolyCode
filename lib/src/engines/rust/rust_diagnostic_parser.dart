import '../../models/diagnostic.dart';

/// Parses standard Rust compiler (`rustc`) output into structured [Diagnostic] objects.
class RustDiagnosticParser {
  RustDiagnosticParser._();

  static final RegExp _headerRegex = RegExp(
    r'^(?<sev>error|warning|note|help)(?:\[(?<code>[A-Z0-9]+)\])?:\s*(?<msg>.+)$',
    multiLine: true,
  );

  static final RegExp _locationRegex = RegExp(
    r'^\s*-->\s*(?<file>[^:\n\r]+):(?<line>\d+):(?<col>\d+)',
    multiLine: true,
  );

  /// Extracts structured diagnostics from `rustc` stderr/stdout text.
  static List<Diagnostic> parse(String output) {
    if (output.trim().isEmpty) return const [];

    final diagnostics = <Diagnostic>[];
    final lines = output.split('\n');

    String? currentSeverity;
    String? currentMessage;
    int? currentLine;
    int? currentColumn;
    String? currentFile;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final headerMatch = _headerRegex.firstMatch(line);

      if (headerMatch != null) {
        // Flush previous diagnostic if present
        if (currentMessage != null) {
          diagnostics.add(
            _createDiagnostic(
              currentMessage,
              currentSeverity,
              currentLine,
              currentColumn,
              currentFile,
            ),
          );
          currentLine = null;
          currentColumn = null;
          currentFile = null;
        }

        final sevStr = headerMatch.namedGroup('sev')?.toLowerCase() ?? 'error';
        final code = headerMatch.namedGroup('code');
        final rawMsg = headerMatch.namedGroup('msg')?.trim() ?? '';

        currentSeverity = sevStr;
        currentMessage = code != null ? '[$code] $rawMsg' : rawMsg;

        // Check if next line contains location pointer `--> main.rs:2:5`
        if (i + 1 < lines.length) {
          final locMatch = _locationRegex.firstMatch(lines[i + 1]);
          if (locMatch != null) {
            currentFile = locMatch.namedGroup('file')?.trim();
            currentLine = int.tryParse(locMatch.namedGroup('line') ?? '');
            currentColumn = int.tryParse(locMatch.namedGroup('col') ?? '');
            i++;
          }
        }
      }
    }

    if (currentMessage != null) {
      diagnostics.add(
        _createDiagnostic(
          currentMessage,
          currentSeverity,
          currentLine,
          currentColumn,
          currentFile,
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

  static Diagnostic _createDiagnostic(
    String message,
    String? sevStr,
    int? line,
    int? col,
    String? file,
  ) {
    final severity = (sevStr == 'warning')
        ? DiagnosticSeverity.warning
        : (sevStr == 'note' || sevStr == 'help')
            ? DiagnosticSeverity.info
            : DiagnosticSeverity.error;

    return Diagnostic(
      message: message,
      severity: severity,
      line: line,
      column: col,
      fileName: file,
    );
  }
}
