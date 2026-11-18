/// Availability status of a language on the current platform runtime.
enum LanguageStatus {
  available,
  experimental,
  requiresRuntime,
  planned,
  unsupported;

  bool get isRunnable =>
      this == LanguageStatus.available || this == LanguageStatus.experimental;
}
