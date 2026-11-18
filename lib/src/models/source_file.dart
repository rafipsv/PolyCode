import 'package:meta/meta.dart';

/// Represents a source code file in an execution workspace.
@immutable
class SourceFile {
  const SourceFile({
    required this.name,
    required this.content,
    this.isEntry = false,
  });

  final String name;
  final String content;
  final bool isEntry;

  SourceFile copyWith({
    String? name,
    String? content,
    bool? isEntry,
  }) {
    return SourceFile(
      name: name ?? this.name,
      content: content ?? this.content,
      isEntry: isEntry ?? this.isEntry,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceFile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          content == other.content &&
          isEntry == other.isEntry;

  @override
  int get hashCode => Object.hash(name, content, isEntry);

  @override
  String toString() =>
      'SourceFile(name: $name, isEntry: $isEntry, length: ${content.length})';
}
