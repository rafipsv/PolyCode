import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('JavaScriptEngine', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('verifies engine capabilities', () async {
      final engine = JavaScriptEngine();
      final caps = await engine.getCapabilities();

      expect(caps.supportedModes, contains(ExecutionMode.interpreted));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.upstreamEngineName, contains('JavaScript'));
    });

    test('executes basic console.log and arithmetic', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.javascript,
          source: '''
const a = 10;
const b = 25;
console.log("Sum:", a + b);
''',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Sum: 35'));
    });

    test('streams multiple stdout chunks', () async {
      final events = <ExecutionEvent>[];

      await for (final event in polycode.executeStream(
        const ExecutionRequest(
          language: PolyLanguage.javascript,
          source: '''
console.log("Line 1");
console.log("Line 2");
''',
        ),
      )) {
        events.add(event);
      }

      final stdoutEvents = events.whereType<StdoutExecutionEvent>().toList();
      expect(stdoutEvents.isNotEmpty, isTrue);

      final combined = stdoutEvents.map((e) => e.chunk).join();
      expect(combined, contains('Line 1'));
      expect(combined, contains('Line 2'));
    });

    test('handles runtime errors and captures stderr', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.javascript,
          source: '''
throw new Error("Custom JS Exception");
''',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Custom JS Exception'));
    });

    test('handles stdin input via readline()', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.javascript,
          source: '''
const name = readline();
console.log("Hello", name);
''',
          stdin: 'Alice\n',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Hello Alice'));
    });

    test('handles async promise resolution', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.javascript,
          source: '''
return new Promise((resolve) => {
  setTimeout(() => {
    console.log("Async Done");
    resolve();
  }, 20);
});
''',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Async Done'));
    });

    test('enforces timeout on long-running code', () async {
      expect(
        () => polycode.execute(
          const ExecutionRequest(
            language: PolyLanguage.javascript,
            source: '''
while (true) {}
''',
            config: ExecutionConfig(timeout: Duration(milliseconds: 300)),
          ),
        ),
        throwsA(isA<ExecutionTimeoutException>()),
      );
    });
  });
}
