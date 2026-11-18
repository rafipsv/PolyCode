import 'package:meta/meta.dart';
import 'execution_config.dart';
import 'poly_language.dart';
import 'source_file.dart';

/// Request payload to compile or execute code.
@immutable
class ExecutionRequest {
  const ExecutionRequest({
    required this.language,
    this.source,
    this.files = const [],
    this.entryFilename,
    this.stdin = '',
    this.config = const ExecutionConfig(),
  });

  final PolyLanguage language;
  final String? source;
  final List<SourceFile> files;
  final String? entryFilename;
  final String stdin;
  final ExecutionConfig config;

  /// Returns the resolved primary source code.
  String get primarySource {
    if (source != null) return source!;
    if (files.isNotEmpty) {
      if (entryFilename != null) {
        final match = files.where((f) => f.name == entryFilename).firstOrNull;
        if (match != null) return match.content;
      }
      final entry = files.where((f) => f.isEntry).firstOrNull;
      if (entry != null) return entry.content;
      return files.first.content;
    }
    return '';
  }

  /// Returns all source files including single source synthesized into a file.
  List<SourceFile> get allFiles {
    if (files.isNotEmpty) return files;
    final ext = language.extension;
    return [
      SourceFile(
        name: 'main.$ext',
        content: source ?? '',
        isEntry: true,
      ),
    ];
  }

  @override
  String toString() =>
      'ExecutionRequest(lang: ${language.displayName}, files: ${allFiles.length}, stdinLen: ${stdin.length})';
}
