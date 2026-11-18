import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('RustEngine', () {
    late RustEngine engine;

    setUp(() {
      engine = RustEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('verifies Rust engine capabilities', () async {
      final caps = await engine.getCapabilities();
      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.version, contains('Rust 2021'));
    });

    test('compiles and executes valid Rust code', () async {
      const code = '''
fn main() {
    println!("Hello from PolyCode Rust!");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.rust,
        source: code,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Hello from PolyCode Rust!'));
    });

    test('streams execution lifecycle events for Rust', () async {
      const code = '''
fn main() {
    println!("Streamed line 1");
    println!("Streamed line 2");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.rust,
        source: code,
      );

      final events = await engine.executeStream(request).toList();
      expect(events.any((e) => e is StdoutExecutionEvent), isTrue);
      expect(events.any((e) => e is CompletedExecutionEvent), isTrue);
    });

    test('captures structured diagnostics on Rust syntax error', () async {
      const invalidCode = '''
fn main() {
    println!("Missing closing brace"
''';
      const request = ExecutionRequest(
        language: PolyLanguage.rust,
        source: invalidCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((d) => d.message.contains('delimiter')),
        isTrue,
      );
    });

    test('detects missing main function in Rust', () async {
      const noMainCode = '''
fn helper() {
    println!("No main function");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.rust,
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

    test('handles stdin in Rust program', () async {
      const codeWithStdin = '''
fn main() {
    println!("Reading stdin...");
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.rust,
        source: codeWithStdin,
        stdin: '42\n',
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('42'));
    });

    test('RustDiagnosticParser parses compiler diagnostic output', () {
      const rustError = '''
error[E0425]: cannot find value `x` in this scope
 --> main.rs:3:5
  |
3 |     x = 10;
  |     ^ not found in this scope
''';
      final diags = RustDiagnosticParser.parse(rustError);
      expect(diags, isNotEmpty);
      expect(diags.first.severity, equals(DiagnosticSeverity.error));
      expect(diags.first.line, equals(3));
      expect(diags.first.column, equals(5));
      expect(diags.first.message, contains('cannot find value'));
    });
  });
}
