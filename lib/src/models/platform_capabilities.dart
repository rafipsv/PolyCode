import 'package:meta/meta.dart';
import 'language_info.dart';
import 'poly_language.dart';
import 'poly_platform.dart';

/// Aggregated platform execution capabilities.
@immutable
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.platform,
    required this.languages,
    this.supportsWebAssembly = true,
    this.supportsWebWorkers = true,
  });

  final PolyPlatform platform;
  final Map<PolyLanguage, LanguageInfo> languages;
  final bool supportsWebAssembly;
  final bool supportsWebWorkers;

  List<PolyLanguage> get availableLanguages => languages.entries
      .where((entry) => entry.value.isRunnable)
      .map((entry) => entry.key)
      .toList(growable: false);

  LanguageInfo? getInfo(PolyLanguage language) => languages[language];

  @override
  String toString() =>
      'PlatformCapabilities(platform: ${platform.name}, runnable: ${availableLanguages.length})';
}
