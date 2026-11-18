import '../models/compilation_result.dart';
import '../models/poly_language.dart';
import '../models/poly_platform.dart';

/// Base exception for all PolyCode errors.
class PolyCodeException implements Exception {
  const PolyCodeException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when no registered engine can handle the requested language.
class EngineNotFoundException extends PolyCodeException {
  EngineNotFoundException(this.language)
      : super('No execution engine registered for ${language.displayName}.');
  final PolyLanguage language;
}

/// Thrown when a language is recognized but unsupported on the platform.
class UnsupportedLanguageException extends PolyCodeException {
  UnsupportedLanguageException(this.language, [String? reason])
      : super(
          'Language ${language.displayName} is unsupported on this platform${reason != null ? ': $reason' : '.'}',
        );
  final PolyLanguage language;
}

/// Thrown when a feature or runtime is not supported on the target OS/environment.
class UnsupportedPlatformException extends PolyCodeException {
  UnsupportedPlatformException(this.platform, String feature)
      : super('Feature "$feature" is not supported on platform ${platform.name}.');
  final PolyPlatform platform;
}

/// Thrown when compilation fails for a compiled language.
class CompilationException extends PolyCodeException {
  const CompilationException({
    required String message,
    required this.compilationResult,
  }) : super(message);

  final CompilationResult compilationResult;
}

/// Thrown when execution exceeds the configured duration timeout.
class ExecutionTimeoutException extends PolyCodeException {
  ExecutionTimeoutException(this.timeout)
      : super('Execution timed out after ${timeout.inSeconds} seconds.');
  final Duration timeout;
}

/// Thrown when an active execution is explicitly cancelled.
class ExecutionCancelledException extends PolyCodeException {
  const ExecutionCancelledException() : super('Execution was cancelled by the caller.');
}

/// Thrown when stdout/stderr streams exceed the maximum configured byte limit.
class OutputLimitExceededException extends PolyCodeException {
  const OutputLimitExceededException(this.limitBytes)
      : super('Execution output exceeded maximum limit of $limitBytes bytes.');
  final int limitBytes;
}

/// Thrown when an engine fails to initialize or load its runtime assets.
class EngineInitializationException extends PolyCodeException {
  const EngineInitializationException(super.message, [this.cause]);
  final Object? cause;
}
