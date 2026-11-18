import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('GoEngine', () {
    late GoEngine engine;

    setUp(() {
      engine = GoEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('verifies Go engine capabilities', () async {
      final caps = await engine.getCapabilities();
      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.version, contains('Go 1.22+'));
    });

    test('compiles and executes valid Go code', () async {
      const code = '''
package main

import "fmt"

func main() {
    fmt.Println("Hello from PolyCode Go!")
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.go,
        source: code,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Hello from PolyCode Go!'));
    });

    test('streams execution lifecycle events for Go', () async {
      const code = '''
package main

import "fmt"

func main() {
    fmt.Println("Line 1")
    fmt.Println("Line 2")
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.go,
        source: code,
      );

      final events = await engine.executeStream(request).toList();
      expect(events.any((e) => e is StdoutExecutionEvent), isTrue);
      expect(events.any((e) => e is CompletedExecutionEvent), isTrue);
    });

    test('captures structured diagnostics on Go syntax error', () async {
      const invalidCode = '''
package main

func main() {
    fmt.Println("Missing brace"
''';
      const request = ExecutionRequest(
        language: PolyLanguage.go,
        source: invalidCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((d) =>
            d.message.contains('syntax error') ||
            d.message.contains('unexpected')),
        isTrue,
      );
    });

    test('detects missing package main or func main in Go', () async {
      const noPackageCode = '''
func main() {
    println("No package")
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.go,
        source: noPackageCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((d) => d.message.contains('package main')),
        isTrue,
      );
    });

    test('handles stdin in Go program', () async {
      const codeWithStdin = '''
package main

import "fmt"

func main() {
    fmt.Println("Reading stdin...")
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.go,
        source: codeWithStdin,
        stdin: '999\n',
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('999'));
    });

    test('GoDiagnosticParser parses standard compiler diagnostic output', () {
      const goError = '''
main.go:4:2: undefined: fmt.Printl
main.go:6:10: syntax error: unexpected semicolon
''';
      final diags = GoDiagnosticParser.parse(goError);
      expect(diags, hasLength(2));
      expect(diags[0].line, equals(4));
      expect(diags[0].column, equals(2));
      expect(diags[0].message, contains('undefined: fmt.Printl'));
      expect(diags[1].line, equals(6));
      expect(diags[1].column, equals(10));
      expect(diags[1].message, contains('syntax error'));
    });
  });
}
