/// Supported programming languages in the PolyCode ecosystem.
enum PolyLanguage {
  c('c', 'C', 'c'),
  cpp('cpp', 'C++', 'cpp'),
  python('python', 'Python', 'py'),
  javascript('javascript', 'JavaScript', 'js'),
  java('java', 'Java', 'java'),
  kotlin('kotlin', 'Kotlin', 'kt'),
  dart('dart', 'Dart', 'dart'),
  rust('rust', 'Rust', 'rs'),
  go('go', 'Go', 'go');

  const PolyLanguage(this.id, this.displayName, this.extension);

  final String id;
  final String displayName;
  final String extension;

  static PolyLanguage? fromId(String id) {
    for (final lang in PolyLanguage.values) {
      if (lang.id.toLowerCase() == id.toLowerCase()) {
        return lang;
      }
    }
    return null;
  }
}
