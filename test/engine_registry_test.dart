import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';
import 'fakes/fake_engine.dart';

void main() {
  group('EngineRegistry', () {
    late EngineRegistry registry;

    setUp(() {
      registry = EngineRegistry();
    });

    test('registers and retrieves engine', () {
      final engine = FakeEngine(language: PolyLanguage.python);
      registry.registerEngine(engine);

      expect(registry.hasEngine(PolyLanguage.python), isTrue);
      expect(registry.getEngine(PolyLanguage.python), equals(engine));
    });

    test('throws EngineNotFoundException for unregistered language', () {
      expect(
        () => registry.getEngine(PolyLanguage.rust),
        throwsA(isA<EngineNotFoundException>()),
      );
    });

    test('unregisters engine correctly', () {
      final engine = FakeEngine(language: PolyLanguage.javascript);
      registry.registerEngine(engine);
      expect(registry.hasEngine(PolyLanguage.javascript), isTrue);

      final removed = registry.unregisterEngine(PolyLanguage.javascript);
      expect(removed, isTrue);
      expect(registry.hasEngine(PolyLanguage.javascript), isFalse);
    });

    test('dispose calls dispose on all registered engines', () async {
      final engine1 = FakeEngine(language: PolyLanguage.c);
      final engine2 = FakeEngine(language: PolyLanguage.cpp);

      registry.registerEngine(engine1);
      registry.registerEngine(engine2);

      await registry.dispose();

      expect(engine1.isDisposed, isTrue);
      expect(engine2.isDisposed, isTrue);
      expect(registry.engines, isEmpty);
    });
  });
}
