import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('PythonEngine', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('verifies engine capabilities', () async {
      final engine = PythonEngine();
      final caps = await engine.getCapabilities();

      expect(caps.supportedModes, contains(ExecutionMode.interpreted));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.upstreamEngineName, contains('Python'));
    });

    test('executes basic print and arithmetic in Python', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: '''
a = 15
b = 30
print("Result:", a + b)
''',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Result: 45'));
    });

    test('executes Python functions and recursion', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: '''
def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

print("Fib:", fib(7))
''',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Fib: 13'));
    });

    test('streams multiple stdout chunks', () async {
      final events = <ExecutionEvent>[];

      await for (final event in polycode.executeStream(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: '''
print("PyLine 1")
print("PyLine 2")
''',
        ),
      )) {
        events.add(event);
      }

      final stdoutEvents = events.whereType<StdoutExecutionEvent>().toList();
      expect(stdoutEvents.isNotEmpty, isTrue);

      final combined = stdoutEvents.map((e) => e.chunk).join();
      expect(combined, contains('PyLine 1'));
      expect(combined, contains('PyLine 2'));
    });

    test('handles runtime exceptions and captures stderr', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: '''
raise ValueError("Invalid Python Parameter")
''',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.exitCode, equals(1));
      expect(result.stderr, contains('Invalid Python Parameter'));
    });

    test('handles stdin input via input()', () async {
      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: '''
user_name = input()
print("Hello", user_name)
''',
          stdin: 'Bob\n',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Hello Bob'));
    });

    test('enforces timeout on infinite loops', () async {
      expect(
        () => polycode.execute(
          const ExecutionRequest(
            language: PolyLanguage.python,
            source: '''
while True:
    pass
''',
            config: ExecutionConfig(timeout: Duration(milliseconds: 300)),
          ),
        ),
        throwsA(isA<ExecutionTimeoutException>()),
      );
    });
  });
}
