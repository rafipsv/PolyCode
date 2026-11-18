import '../models/source_file.dart';

/// Manages virtual and temporary source file workspaces for code execution.
class WorkspaceManager {
  WorkspaceManager();

  final Map<String, SourceFile> _files = {};

  /// Current files in this workspace.
  Map<String, SourceFile> get files => Map.unmodifiable(_files);

  /// Adds or updates a file in the workspace.
  void setFile(SourceFile file) {
    _files[file.name] = file;
  }

  /// Removes a file from the workspace.
  bool removeFile(String fileName) {
    return _files.remove(fileName) != null;
  }

  /// Retrieves a file by its name.
  SourceFile? getFile(String fileName) => _files[fileName];

  /// Clears all files in the workspace.
  void clear() {
    _files.clear();
  }

  /// Validates that an entry file exists or can be determined deterministically.
  SourceFile resolveEntryFile([String? specifiedEntry]) {
    if (specifiedEntry != null && _files.containsKey(specifiedEntry)) {
      return _files[specifiedEntry]!;
    }
    final explicitEntry = _files.values.where((f) => f.isEntry).firstOrNull;
    if (explicitEntry != null) return explicitEntry;

    if (_files.isNotEmpty) return _files.values.first;

    throw StateError('Workspace contains no files to resolve an entry point.');
  }
}
