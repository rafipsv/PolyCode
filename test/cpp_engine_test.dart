import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('CppEngine', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('verifies C++ engine capabilities', () async {
      final engine = CppEngine();
      final caps = await engine.getCapabilities();

      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.upstreamEngineName, contains('Clang++'));
    });

    test('compiles and executes valid modern C++ code', () async {
      const source = '''
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers = {10, 20, 30};
    int total = 0;
    for (int n : numbers) {
        total += n;
    }
    std::cout << "Total: " << total << std::endl;
    return 0;
}
''';

      final compResult = await polycode.compile(
        const ExecutionRequest(
          language: PolyLanguage.cpp,
          source: source,
        ),
      );

      expect(compResult.isSuccess, isTrue);
      expect(compResult.artifact, isNotNull);

      final execResult = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.cpp,
          source: source,
        ),
      );

      expect(execResult.isSuccess, isTrue);
      expect(execResult.exitCode, equals(0));
      expect(execResult.stdout, contains('Total: 60'));
    });

    test('captures structured diagnostics on C++ syntax error', () async {
      const invalidSource = '''
#include <iostream>

int main() {
    UnknownType x = 42;
    return 0;
}
''';

      final compResult = await polycode.compile(
        const ExecutionRequest(
          language: PolyLanguage.cpp,
          source: invalidSource,
        ),
      );

      expect(compResult.isSuccess, isFalse);
      expect(compResult.diagnostics.isNotEmpty, isTrue);
      expect(compResult.diagnostics.first.severity,
          equals(DiagnosticSeverity.error));
    });

    test('handles stdin in C++ program via std::cin', () async {
      const source = '''
#include <iostream>
#include <string>

int main() {
    std::string word;
    if (std::cin >> word) {
        std::cout << "Echo: " << word << std::endl;
    }
    return 0;
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.cpp,
          source: source,
          stdin: 'FastCppRunner\n',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('Echo: FastCppRunner'));
    });

    test('enforces timeout on infinite loops in C++', () async {
      const source = '''
int main() {
    for (;;) {}
    return 0;
}
''';

      expect(
        () => polycode.execute(
          const ExecutionRequest(
            language: PolyLanguage.cpp,
            source: source,
            config: ExecutionConfig(timeout: Duration(milliseconds: 400)),
          ),
        ),
        throwsA(isA<ExecutionTimeoutException>()),
      );
    });
  });
}
