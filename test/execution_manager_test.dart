import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';
import 'fakes/fake_engine.dart';

void main() {
  group('ExecutionManager', () {
    late LanguageRegistry languageRegistry;
    late EngineRegistry engineRegistry;
    late ExecutionManager executionManager;

    setUp(() {
      languageRegistry = LanguageRegistry();
      engineRegistry = EngineRegistry();
      executionManager = ExecutionManager(
        engineRegistry: engineRegistry,
        languageRegistry: languageRegistry,
      );
    });

    test('executes request and returns stdout', () async {
      final fakeEngine = FakeEngine(
        language: PolyLanguage.python,
        simulatedStdout: 'Hello Python Output\n',
      );
      engineRegistry.registerEngine(fakeEngine);

      final result = await executionManager.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: 'print("hello")',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Hello Python Output'));
      expect(result.exitCode, equals(0));
    });

    test('executes request passing stdin', () async {
      final fakeEngine = FakeEngine(language: PolyLanguage.python);
      engineRegistry.registerEngine(fakeEngine);

      final result = await executionManager.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: 'input()',
          stdin: 'custom input data',
        ),
      );

      expect(result.stdout, contains('[stdin received: custom input data]'));
    });

    test('handles compilation failure correctly', () async {
      final fakeEngine = FakeEngine(
        language: PolyLanguage.c,
        shouldFailCompilation: true,
      );
      engineRegistry.registerEngine(fakeEngine);

      expect(
        () => executionManager.execute(
          const ExecutionRequest(
            language: PolyLanguage.c,
            source: 'invalid syntax',
          ),
        ),
        throwsA(isA<CompilationException>()),
      );
    });

    test('enforces timeout correctly', () async {
      final fakeEngine = FakeEngine(
        language: PolyLanguage.python,
        executionDelay: const Duration(milliseconds: 300),
      );
      engineRegistry.registerEngine(fakeEngine);

      expect(
        () => executionManager.execute(
          const ExecutionRequest(
            language: PolyLanguage.python,
            source: 'while True: pass',
            config: ExecutionConfig(timeout: Duration(milliseconds: 50)),
          ),
        ),
        throwsA(isA<ExecutionTimeoutException>()),
      );
    });

    test('supports explicit cancellation via CancellationToken', () async {
      final fakeEngine = FakeEngine(
        language: PolyLanguage.python,
        executionDelay: const Duration(milliseconds: 200),
      );
      engineRegistry.registerEngine(fakeEngine);

      final cancelToken = CancellationToken();
      Future<void>.delayed(const Duration(milliseconds: 30), () {
        cancelToken.cancel();
      });

      final events = <ExecutionEvent>[];
      await for (final event in executionManager.executeStream(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: 'long_running()',
        ),
        cancelToken: cancelToken,
      )) {
        events.add(event);
      }

      expect(events.any((e) => e is CancelledExecutionEvent), isTrue);
    });

    test('truncates output when maxOutputBytes is exceeded', () async {
      final largeOutput = 'A' * 2000;
      final fakeEngine = FakeEngine(
        language: PolyLanguage.python,
        simulatedStdout: largeOutput,
      );
      engineRegistry.registerEngine(fakeEngine);

      final result = await executionManager.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: 'print("A" * 2000)',
          config: ExecutionConfig(maxOutputBytes: 500),
        ),
      );

      expect(result.isOutputLimitExceeded, isTrue);
      expect(result.stdout,
          contains('Output truncated: exceeded 500 bytes limit'));
    });
  });
}
