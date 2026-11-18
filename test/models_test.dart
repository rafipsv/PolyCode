import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('Models & Utilities', () {
    test('PolyLanguage fromId resolves case-insensitively', () {
      expect(PolyLanguage.fromId('python'), equals(PolyLanguage.python));
      expect(PolyLanguage.fromId('CPP'), equals(PolyLanguage.cpp));
      expect(PolyLanguage.fromId('javascript'), equals(PolyLanguage.javascript));
      expect(PolyLanguage.fromId('unknown'), isNull);
    });

    test('SourceFile equality and copyWith', () {
      const file1 = SourceFile(name: 'main.py', content: 'print(1)', isEntry: true);
      const file2 = SourceFile(name: 'main.py', content: 'print(1)', isEntry: true);
      expect(file1, equals(file2));

      final updated = file1.copyWith(content: 'print(2)');
      expect(updated.content, equals('print(2)'));
      expect(updated.name, equals('main.py'));
      expect(updated.isEntry, isTrue);
    });

    test('ExecutionRequest resolves primary source from single source or files', () {
      const reqSingle = ExecutionRequest(
        language: PolyLanguage.python,
        source: 'print("single")',
      );
      expect(reqSingle.primarySource, equals('print("single")'));
      expect(reqSingle.allFiles.length, equals(1));
      expect(reqSingle.allFiles.first.name, equals('main.py'));

      const reqMulti = ExecutionRequest(
        language: PolyLanguage.python,
        files: [
          SourceFile(name: 'helper.py', content: 'def f(): pass'),
          SourceFile(name: 'app.py', content: 'import helper', isEntry: true),
        ],
      );
      expect(reqMulti.primarySource, equals('import helper'));
    });

    test('WorkspaceManager manages files and resolves entry point', () {
      final workspace = WorkspaceManager();
      const f1 = SourceFile(name: 'module.py', content: 'x = 10');
      const f2 = SourceFile(name: 'entry.py', content: 'print(x)', isEntry: true);

      workspace.setFile(f1);
      workspace.setFile(f2);

      expect(workspace.files.length, equals(2));
      expect(workspace.resolveEntryFile().name, equals('entry.py'));

      workspace.removeFile('entry.py');
      expect(workspace.resolveEntryFile().name, equals('module.py'));

      workspace.clear();
      expect(() => workspace.resolveEntryFile(), throwsStateError);
    });

    test('Diagnostic formatting and severity', () {
      const diag = Diagnostic(
        message: 'Undefined variable',
        severity: DiagnosticSeverity.error,
        line: 10,
        column: 5,
        fileName: 'main.py',
      );
      expect(diag.toString(), contains('[ERROR] Undefined variable (line: 10, col: 5)'));
    });
  });
}
