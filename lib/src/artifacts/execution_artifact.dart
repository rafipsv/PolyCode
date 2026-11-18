import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../models/poly_language.dart';

/// Represents a compiled or bundled executable artifact.
@immutable
class ExecutionArtifact {
  ExecutionArtifact({
    required this.id,
    required this.language,
    required this.bytes,
    this.entryPoint = 'main',
    this.metadata = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final PolyLanguage language;
  final Uint8List bytes;
  final String entryPoint;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  int get sizeBytes => bytes.lengthInBytes;

  @override
  String toString() =>
      'ExecutionArtifact(id: $id, lang: ${language.displayName}, size: $sizeBytes bytes)';
}
