import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';
import 'fakes/fake_engine.dart';

void main() {
  group('PolyCode Facade', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('initializes with platform capabilities and default engines', () {
      final capabilities = polycode.getPlatformCapabilities();
      expect(capabilities.languages.length, equals(9));
      expect(polycode.isEngineAvailable(PolyLanguage.javascript), isTrue);
      expect(polycode.isEngineAvailable(PolyLanguage.python), isTrue);
      expect(polycode.isEngineAvailable(PolyLanguage.c), isTrue);
      expect(polycode.isEngineAvailable(PolyLanguage.cpp), isTrue);
      expect(
          capabilities.availableLanguages, contains(PolyLanguage.javascript));
      expect(capabilities.availableLanguages, contains(PolyLanguage.python));
      expect(capabilities.availableLanguages, contains(PolyLanguage.c));
      expect(capabilities.availableLanguages, contains(PolyLanguage.cpp));
    });

    test('respects autoRegisterDefaults false', () {
      final barePolycode = PolyCode(autoRegisterDefaults: false);
      expect(
          barePolycode.getPlatformCapabilities().availableLanguages, isEmpty);
      expect(barePolycode.isEngineAvailable(PolyLanguage.javascript), isFalse);
    });

    test('registering engine activates language in capabilities', () {
      final fake = FakeEngine(language: PolyLanguage.javascript);
      polycode.registerEngine(fake);

      expect(polycode.isEngineAvailable(PolyLanguage.javascript), isTrue);
      final caps = polycode.getPlatformCapabilities();
      expect(caps.availableLanguages, contains(PolyLanguage.javascript));
      final info = polycode.getLanguageInfo(PolyLanguage.javascript);
      expect(info!.status, equals(LanguageStatus.available));
    });

    test('executes code through facade', () async {
      final fake = FakeEngine(
        language: PolyLanguage.python,
        simulatedStdout: 'PolyCode Facade Test\n',
      );
      polycode.registerEngine(fake);

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: 'print("hello")',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('PolyCode Facade Test'));
    });

    test('unregisters engine correctly', () {
      final fake = FakeEngine(language: PolyLanguage.python);
      polycode.registerEngine(fake);
      expect(polycode.isEngineAvailable(PolyLanguage.python), isTrue);

      polycode.unregisterEngine(PolyLanguage.python);
      expect(polycode.isEngineAvailable(PolyLanguage.python), isFalse);
    });

    test('dispose cleans up all registered engines', () async {
      final fake = FakeEngine(language: PolyLanguage.python);
      polycode.registerEngine(fake);

      await polycode.dispose();
      expect(fake.isDisposed, isTrue);
    });
  });
}
