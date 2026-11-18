import 'package:meta/meta.dart';

/// Global configuration for the PolyCode runtime instance.
@immutable
class PolyCodeConfig {
  const PolyCodeConfig({
    this.defaultTimeout = const Duration(seconds: 15),
    this.defaultMaxOutputBytes = 256 * 1024,
    this.defaultMemoryLimitMb = 128,
    this.enableDiagnostics = true,
  });

  final Duration defaultTimeout;
  final int defaultMaxOutputBytes;
  final int defaultMemoryLimitMb;
  final bool enableDiagnostics;

  @override
  String toString() =>
      'PolyCodeConfig(timeout: ${defaultTimeout.inSeconds}s, maxBytes: $defaultMaxOutputBytes)';
}
