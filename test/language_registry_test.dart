import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('LanguageRegistry', () {
    late LanguageRegistry registry;

    setUp(() {
      registry = LanguageRegistry(platform: PolyPlatform.web);
    });

    test('initializes all nine target languages', () {
      final all = registry.allLanguages;
      expect(all.length, equals(9));
      expect(all.containsKey(PolyLanguage.c), isTrue);
      expect(all.containsKey(PolyLanguage.cpp), isTrue);
      expect(all.containsKey(PolyLanguage.python), isTrue);
      expect(all.containsKey(PolyLanguage.javascript), isTrue);
      expect(all.containsKey(PolyLanguage.java), isTrue);
      expect(all.containsKey(PolyLanguage.kotlin), isTrue);
      expect(all.containsKey(PolyLanguage.dart), isTrue);
      expect(all.containsKey(PolyLanguage.rust), isTrue);
      expect(all.containsKey(PolyLanguage.go), isTrue);
    });

    test('all languages are initially planned and not runnable in Phase 0/1', () {
      expect(registry.runnableLanguages, isEmpty);
      for (final lang in PolyLanguage.values) {
        final info = registry.getInfo(lang);
        expect(info, isNotNull);
        expect(info!.isRunnable, isFalse);
        expect(info.status, equals(LanguageStatus.planned));
      }
    });

    test('status changes to available when updated', () {
      registry.setStatus(PolyLanguage.python, LanguageStatus.available, reason: 'Engine attached');
      final info = registry.getInfo(PolyLanguage.python);
      expect(info!.status, equals(LanguageStatus.available));
      expect(info.isRunnable, isTrue);
      expect(registry.runnableLanguages, contains(PolyLanguage.python));
    });
  });
}
