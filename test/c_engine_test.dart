import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('CEngine', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('verifies C engine capabilities', () async {
      final engine = CEngine();
      final caps = await engine.getCapabilities();

      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.upstreamEngineName, contains('Clang'));
    });

    test('compiles and executes valid C code', () async {
      const source = '''
#include <stdio.h>

int main() {
    printf("Hello C PolyCode\\n");
    return 0;
}
''';

      final compResult = await polycode.compile(
        const ExecutionRequest(
          language: PolyLanguage.c,
          source: source,
        ),
      );

      expect(compResult.isSuccess, isTrue);
      expect(compResult.artifact, isNotNull);

      final execResult = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.c,
          source: source,
        ),
      );

      expect(execResult.isSuccess, isTrue);
      expect(execResult.exitCode, equals(0));
      expect(execResult.stdout, contains('Hello C PolyCode'));
    });

    test('captures structured diagnostics on C syntax error', () async {
      const invalidSource = '''
#include <stdio.h>

int main() {
    printf("Missing semicolon")
    return 0;
}
''';

      final compResult = await polycode.compile(
        const ExecutionRequest(
          language: PolyLanguage.c,
          source: invalidSource,
        ),
      );

      expect(compResult.isSuccess, isFalse);
      expect(compResult.diagnostics.isNotEmpty, isTrue);
      expect(compResult.diagnostics.first.severity,
          equals(DiagnosticSeverity.error));
      expect(compResult.diagnostics.first.line, isNotNull);
    });

    test('handles stdin in C program', () async {
      const source = '''
#include <stdio.h>

int main() {
    char name[64];
    if (scanf("%63s", name) == 1) {
        printf("Greeting: %s\\n", name);
    }
    return 0;
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.c,
          source: source,
          stdin: 'PolyCoder\n',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Greeting: PolyCoder'));
    });

    test('enforces timeout on infinite loops in C', () async {
      const source = '''
int main() {
    while (1) {}
    return 0;
}
''';

      expect(
        () => polycode.execute(
          const ExecutionRequest(
            language: PolyLanguage.c,
            source: source,
            config: ExecutionConfig(timeout: Duration(milliseconds: 400)),
          ),
        ),
        throwsA(isA<ExecutionTimeoutException>()),
      );
    });
  });
}
