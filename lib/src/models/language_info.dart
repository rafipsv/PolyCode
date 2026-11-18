import 'package:meta/meta.dart';
import 'execution_mode.dart';
import 'language_status.dart';
import 'poly_language.dart';

/// Comprehensive metadata about a language's runtime configuration.
@immutable
class LanguageInfo {
  const LanguageInfo({
    required this.language,
    required this.status,
    required this.supportedModes,
    this.runtimeName,
    this.runtimeVersion,
    this.statusReason,
    this.downloadSizeBytes,
    this.isOfflineReady = false,
  });

  final PolyLanguage language;
  final LanguageStatus status;
  final Set<ExecutionMode> supportedModes;
  final String? runtimeName;
  final String? runtimeVersion;
  final String? statusReason;
  final int? downloadSizeBytes;
  final bool isOfflineReady;

  bool get isRunnable => status.isRunnable;

  LanguageInfo copyWith({
    PolyLanguage? language,
    LanguageStatus? status,
    Set<ExecutionMode>? supportedModes,
    String? runtimeName,
    String? runtimeVersion,
    String? statusReason,
    int? downloadSizeBytes,
    bool? isOfflineReady,
  }) {
    return LanguageInfo(
      language: language ?? this.language,
      status: status ?? this.status,
      supportedModes: supportedModes ?? this.supportedModes,
      runtimeName: runtimeName ?? this.runtimeName,
      runtimeVersion: runtimeVersion ?? this.runtimeVersion,
      statusReason: statusReason ?? this.statusReason,
      downloadSizeBytes: downloadSizeBytes ?? this.downloadSizeBytes,
      isOfflineReady: isOfflineReady ?? this.isOfflineReady,
    );
  }

  @override
  String toString() => 'LanguageInfo(${language.displayName}, status: ${status.name})';
}
