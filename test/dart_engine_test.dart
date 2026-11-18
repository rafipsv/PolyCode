import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('DartEngine', () {
    late DartEngine engine;

    setUp(() {
      engine = DartEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('verifies Dart engine capabilities', () async {
      final caps = await engine.getCapabilities();
      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.version, contains('Dart 3'));
    });

    test('compiles and executes valid Dart code', () async {
      const code = '''
void main() {
  print('Hello from PolyCode Dart!');
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.dart,
        source: code,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Hello from PolyCode Dart!'));
    });

    test('streams execution lifecycle events for Dart', () async {
      const code = '''
void main() {
  print('Streamed line 1');
  print('Streamed line 2');
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.dart,
        source: code,
      );

      final events = await engine.executeStream(request).toList();
      expect(events.any((e) => e is StdoutExecutionEvent), isTrue);
      expect(events.any((e) => e is CompletedExecutionEvent), isTrue);
    });

    test('captures structured diagnostics on Dart syntax error', () async {
      const invalidCode = '''
void main() {
  print('Missing closing brace'
''';
      const request = ExecutionRequest(
        language: PolyLanguage.dart,
        source: invalidCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics.isNotEmpty || result.stderr.isNotEmpty,
        isTrue,
      );
    });

    test('detects missing main function in Dart', () async {
      const noMainCode = '''
void helper() {
  print('No main');
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.dart,
        source: noMainCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(
        result.diagnostics
                .any((d) => d.message.toLowerCase().contains('main')) ||
            result.stderr.toLowerCase().contains('main'),
        isTrue,
      );
    });

    test('handles stdin in Dart program', () async {
      const codeWithStdin = '''
import 'dart:io';

void main() {
  final line = stdin.readLineSync();
  print('Echo: \$line');
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.dart,
        source: codeWithStdin,
        stdin: 'DartStdinData\n',
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('DartStdinData'));
    });

    test('DartDiagnosticParser parses compiler diagnostic output', () {
      const dartError = '''
main.dart:3:5: Error: Expected ';' after this.
    int x = 10
        ^
''';
      final diags = DartDiagnosticParser.parse(dartError);
      expect(diags, isNotEmpty);
      expect(diags.first.severity, equals(DiagnosticSeverity.error));
      expect(diags.first.line, equals(3));
      expect(diags.first.column, equals(5));
      expect(diags.first.fileName, equals('main.dart'));
      expect(diags.first.message, contains("Expected ';' after this"));
    });
  });
}
