import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('JavaEngine', () {
    late JavaEngine engine;

    setUp(() {
      engine = JavaEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('verifies Java engine capabilities', () async {
      final caps = await engine.getCapabilities();
      expect(caps.supportedModes, contains(ExecutionMode.compiled));
      expect(caps.supportsStdin, isTrue);
      expect(caps.supportsStreaming, isTrue);
      expect(caps.supportsCancellation, isTrue);
      expect(caps.version, contains('Java 17+'));
    });

    test('compiles and executes valid Java code', () async {
      const code = '''
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from PolyCode Java!");
    }
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.java,
        source: code,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('Hello from PolyCode Java!'));
    });

    test('streams execution lifecycle events for Java', () async {
      const code = '''
public class Main {
    public static void main(String[] args) {
        System.out.println("Streamed line 1");
        System.out.println("Streamed line 2");
    }
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.java,
        source: code,
      );

      final events = await engine.executeStream(request).toList();
      expect(events.any((e) => e is StdoutExecutionEvent), isTrue);
      expect(events.any((e) => e is CompletedExecutionEvent), isTrue);
    });

    test('captures structured diagnostics on Java syntax error', () async {
      const invalidCode = '''
public class Main {
    public static void main(String[] args) {
        System.out.println("Missing closing brace"
''';
      const request = ExecutionRequest(
        language: PolyLanguage.java,
        source: invalidCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, isNotEmpty);
      expect(
        result.diagnostics.any((d) => d.message.contains('parsing') || d.message.contains('reached end of file') || d.message.contains('error')),
        isTrue,
      );
    });

    test('detects missing main method in Java', () async {
      const noMainCode = '''
public class Main {
    public void helper() {
        System.out.println("No main method");
    }
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.java,
        source: noMainCode,
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isFalse);
      expect(
        result.stderr.toLowerCase().contains('main') ||
            result.diagnostics.any((d) => d.message.toLowerCase().contains('main')),
        isTrue,
      );
    });

    test('handles stdin in Java program', () async {
      const codeWithStdin = '''
import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        if (sc.hasNextLine()) {
            System.out.println("Echo: " + sc.nextLine());
        }
    }
}
''';
      const request = ExecutionRequest(
        language: PolyLanguage.java,
        source: codeWithStdin,
        stdin: 'JavaStdinData\n',
      );

      final result = await engine.execute(request);
      expect(result.isSuccess, isTrue);
      expect(result.stdout, contains('JavaStdinData'));
    });

    test('JavaDiagnosticParser parses compiler diagnostic output', () {
      const javaError = '''
Main.java:5: error: cannot find symbol
        int x = y + 1;
                ^
  symbol:   variable y
  location: class Main
1 error
''';
      final diags = JavaDiagnosticParser.parse(javaError);
      expect(diags, isNotEmpty);
      expect(diags.first.severity, equals(DiagnosticSeverity.error));
      expect(diags.first.line, equals(5));
      expect(diags.first.fileName, equals('Main.java'));
      expect(diags.first.message, contains('cannot find symbol'));
    });
  });
}
