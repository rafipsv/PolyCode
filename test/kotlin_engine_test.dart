import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('KotlinEngine', () {
    late KotlinEngine engine;

    setUp(() {
      engine = KotlinEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('verifies Kotlin engine capabilities', () async {
      final caps = await engine.getCapabilities();
      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.version, contains('Kotlin 2.0+'));
    });

    test('compiles and executes valid Kotlin code', () async {
      const code = '''
fun main() {
    println("Hello from PolyCode Kotlin!");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.kotlin,
        source: code,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Hello from PolyCode Kotlin!'));
    });

    test('streams execution lifecycle events for Kotlin', () async {
      const code = '''
fun main() {
    println("Streamed line 1");
    println("Streamed line 2");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.kotlin,
        source: code,
      );

      final events = await engine.executeStream(request).toList();
      expect(events.any((e) => e is StdoutExecutionEvent), isTrue);
      expect(events.any((e) => e is CompletedExecutionEvent), isTrue);
    });

    test('captures structured diagnostics on Kotlin syntax error', () async {
      const invalidCode = '''
fun main() {
    println("Missing closing brace"
''';
      const request = ExecutionRequest(
        language: PolyLanguage.kotlin,
        source: invalidCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((d) =>
            d.message.contains('expecting') || d.message.contains('error')),
        isTrue,
      );
    });

    test('detects missing main function in Kotlin', () async {
      const noMainCode = '''
fun helper() {
    println("No main function");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.kotlin,
        source: noMainCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((d) => d.message.contains('main')),
        isTrue,
      );
    });

    test('handles stdin in Kotlin program', () async {
      const codeWithStdin = '''
fun main() {
    println("Reading stdin...");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.kotlin,
        source: codeWithStdin,
        stdin: 'KotlinStdinData\n',
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('KotlinStdinData'));
    });

    test('KotlinDiagnosticParser parses compiler diagnostic output', () {
      const kotlinError = '''
Main.kt:3:5: error: unresolved reference: y
    y = 10
    ^
''';
      final diags = KotlinDiagnosticParser.parse(kotlinError);
      expect(diags, isNotEmpty);
      expect(diags.first.severity, equals(DiagnosticSeverity.error));
      expect(diags.first.line, equals(3));
      expect(diags.first.column, equals(5));
      expect(diags.first.fileName, equals('Main.kt'));
      expect(diags.first.message, contains('unresolved reference'));
    });
  });
}
