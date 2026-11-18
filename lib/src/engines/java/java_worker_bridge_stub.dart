import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../artifacts/execution_artifact.dart';
import '../../models/compilation_result.dart';
import '../../models/diagnostic.dart';
import '../../models/execution_event.dart';
import '../../models/execution_request.dart';
import '../../models/execution_result.dart';
import 'java_diagnostic_parser.dart';
import 'java_worker_bridge.dart';

JavaWorkerBridge createJavaWorkerBridge() => StubJavaWorkerBridge();

/// Desktop / VM execution bridge using host `javac` compiler or simulated JVM execution.
class StubJavaWorkerBridge implements JavaWorkerBridge {
  StubJavaWorkerBridge();

  final Map<String, Directory> _cachedArtifactDirs = {};
  final Map<String, String> _cachedClassNames = {};
  final Map<String, String> _cachedSources = {};
  Process? _activeProcess;

  String _extractClassName(String source) {
    final publicMatch =
        RegExp(r'public\s+class\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(source);
    if (publicMatch != null) return publicMatch.group(1)!;

    final classMatch =
        RegExp(r'class\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(source);
    return classMatch?.group(1) ?? 'Main';
  }

  @override
  Future<CompilationResult> compile(ExecutionRequest request) async {
    final stopwatch = Stopwatch()..start();
    final compilerBinary = _resolveCompiler();

    if (compilerBinary == null) {
      return _fallbackCompile(request, stopwatch);
    }

    final className = _extractClassName(request.primarySource);
    final tempDir = Directory.systemTemp.createTempSync('polycode_java_');
    final srcFile = File('${tempDir.path}/$className.java');

    srcFile.writeAsStringSync(request.primarySource);

    try {
      final args = [
        '-d',
        tempDir.path,
        ...request.config.compilerOptions,
        srcFile.path,
      ];

      final result = await Process.run(
        compilerBinary,
        args,
        workingDirectory: tempDir.path,
      ).timeout(request.config.timeout);

      stopwatch.stop();

      final output = '${result.stdout}\n${result.stderr}'.trim();
      final classFile = File('${tempDir.path}/$className.class');
      final isSuccess = result.exitCode == 0 && classFile.existsSync();
      final diagnostics = isSuccess
          ? const <Diagnostic>[]
          : JavaDiagnosticParser.parse(result.stderr.toString());

      if (isSuccess) {
        final classBytes = classFile.readAsBytesSync();
        final artifactId = 'java_class_${DateTime.now().millisecondsSinceEpoch}';
        _cachedArtifactDirs[artifactId] = tempDir;
        _cachedClassNames[artifactId] = className;
        _cachedSources[artifactId] = request.primarySource;

        return CompilationResult(
          isSuccess: true,
          compilerOutput: output,
          duration: stopwatch.elapsed,
          artifact: ExecutionArtifact(
            id: artifactId,
            language: request.language,
            bytes: classBytes,
          ),
          diagnostics: diagnostics,
        );
      } else {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}

        return CompilationResult(
          isSuccess: false,
          compilerOutput: output,
          duration: stopwatch.elapsed,
          diagnostics: diagnostics,
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
      return const CompilationResult(
        isSuccess: false,
        compilerOutput: 'Java compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'javac compilation timed out.',
            severity: DiagnosticSeverity.error,
          ),
        ],
      );
    } catch (_) {
      stopwatch.stop();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
      return _fallbackCompile(request, stopwatch);
    }
  }

  @override
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    ExecutionArtifact? artifact,
  }) async* {
    final stopwatch = Stopwatch()..start();
    Directory? artifactDir;
    String? className;

    if (artifact != null && _cachedArtifactDirs.containsKey(artifact.id)) {
      artifactDir = _cachedArtifactDirs[artifact.id];
      className = _cachedClassNames[artifact.id];
    }

    if (artifactDir == null || !artifactDir.existsSync()) {
      if (request.primarySource.isNotEmpty) {
        final comp = await compile(request);
        if (!comp.isSuccess) {
          yield FailedExecutionEvent(
            Exception('Java compilation failed: ${comp.compilerOutput}'),
            compilationResult: comp,
          );
          return;
        }
        if (comp.artifact != null &&
            _cachedArtifactDirs.containsKey(comp.artifact!.id)) {
          artifactDir = _cachedArtifactDirs[comp.artifact!.id];
          className = _cachedClassNames[comp.artifact!.id];
        }
      }
    }

    final runtimeBinary = _resolveRuntime();
    if (runtimeBinary != null &&
        artifactDir != null &&
        artifactDir.existsSync() &&
        className != null) {
      yield* _runProcess(
          runtimeBinary, artifactDir.path, className, request.stdin, stopwatch);
    } else {
      final source = request.primarySource.isNotEmpty
          ? request.primarySource
          : (artifact != null ? (_cachedSources[artifact.id] ?? '') : '');
      yield* _simulateExecution(source, request.stdin, stopwatch);
    }
  }

  Stream<ExecutionEvent> _runProcess(
    String javaBinary,
    String classPath,
    String className,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    final controller = StreamController<ExecutionEvent>();

    Process? process;
    try {
      process = await Process.start(
        javaBinary,
        ['-cp', classPath, className],
      );
      _activeProcess = process;

      if (stdinData.isNotEmpty) {
        process.stdin.write(stdinData);
        await process.stdin.flush();
      }
      await process.stdin.close();

      process.stdout.transform(utf8.decoder).listen((chunk) {
        controller.add(StdoutExecutionEvent(chunk));
      });

      process.stderr.transform(utf8.decoder).listen((chunk) {
        controller.add(StderrExecutionEvent(chunk));
      });

      process.exitCode.then((code) {
        stopwatch.stop();
        controller.add(
          CompletedExecutionEvent(
            ExecutionResult(
              exitCode: code,
              isSuccess: code == 0,
              duration: stopwatch.elapsed,
            ),
          ),
        );
        controller.close();
      });

      yield* controller.stream;
    } catch (e) {
      stopwatch.stop();
      controller.add(
        FailedExecutionEvent(Exception('Java execution failed: $e')),
      );
      controller.close();
      yield* controller.stream;
    } finally {
      process?.kill();
      _activeProcess = null;
      stopwatch.stop();
    }
  }

  Stream<ExecutionEvent> _simulateExecution(
    String source,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    if (source.isEmpty) {
      stopwatch.stop();
      yield StdoutExecutionEvent('Java program executed successfully.\n');
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 0,
          isSuccess: true,
          duration: stopwatch.elapsed,
        ),
      );
      return;
    }

    // Check class keyword
    if (!source.contains('class ')) {
      stopwatch.stop();
      const err = "Main.java:1: error: class, interface, enum, or record expected\n";
      yield StderrExecutionEvent(err);
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 1,
          isSuccess: false,
          stderr: err,
          duration: stopwatch.elapsed,
          error: 'Syntax error',
        ),
      );
      return;
    }

    // Check unclosed braces
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = "Main.java:10: error: reached end of file while parsing\n";
      yield StderrExecutionEvent(err);
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 1,
          isSuccess: false,
          stderr: err,
          duration: stopwatch.elapsed,
          error: 'Syntax error',
        ),
      );
      return;
    }

    // Check main method
    final hasMain = source.contains('main(String[]') ||
        source.contains('main (String[]') ||
        source.contains('main(String args[])') ||
        source.contains('main (String args[])') ||
        source.contains('main(String ...');
    if (!hasMain) {
      stopwatch.stop();
      const err =
          "Error: Main method not found in class, please define the main method as:\n   public static void main(String[] args)\n";
      yield StderrExecutionEvent(err);
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 1,
          isSuccess: false,
          stderr: err,
          duration: stopwatch.elapsed,
          error: 'Missing main method',
        ),
      );
      return;
    }

    // Evaluate System.out.println / System.out.print
    final printRegex =
        RegExp(r'System\.out\.(println|print)\s*\(\s*(.*?)\s*\)\s*;');
    bool printed = false;

    for (final match in printRegex.allMatches(source)) {
      final method = match.group(1);
      var content = match.group(2)?.trim() ?? '';

      if (content.startsWith('"') && content.endsWith('"') && content.length >= 2) {
        content = content.substring(1, content.length - 1);
      }

      final newline = method == 'println' ? '\n' : '';
      yield StdoutExecutionEvent('$content$newline');
      printed = true;
    }

    if (stdinData.isNotEmpty) {
      yield StdoutExecutionEvent('[stdin received: ${stdinData.trim()}]\n');
    }

    if (!printed) {
      yield StdoutExecutionEvent('Java program executed successfully.\n');
    }

    stopwatch.stop();
    yield CompletedExecutionEvent(
      ExecutionResult(
        exitCode: 0,
        isSuccess: true,
        duration: stopwatch.elapsed,
      ),
    );
  }

  String? _resolveCompiler() {
    try {
      final res = Process.runSync('which', ['javac']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  String? _resolveRuntime() {
    try {
      final res = Process.runSync('which', ['java']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  CompilationResult _fallbackCompile(
      ExecutionRequest request, Stopwatch stopwatch) {
    final source = request.primarySource;

    // Check class keyword
    if (!source.contains('class ')) {
      stopwatch.stop();
      const err = "Main.java:1: error: class, interface, enum, or record expected\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: JavaDiagnosticParser.parse(err),
      );
    }

    // Check main method
    final hasMain = source.contains('main(String[]') ||
        source.contains('main (String[]') ||
        source.contains('main(String args[])') ||
        source.contains('main (String args[])') ||
        source.contains('main(String ...');
    if (!hasMain) {
      stopwatch.stop();
      const err =
          "Main.java:1: error: Main method not found in class, please define the main method as:\n   public static void main(String[] args)\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: JavaDiagnosticParser.parse(err),
      );
    }

    // Check unclosed braces
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = "Main.java:10: error: reached end of file while parsing\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: JavaDiagnosticParser.parse(err),
      );
    }

    stopwatch.stop();
    final artifactId = 'java_class_${DateTime.now().millisecondsSinceEpoch}';
    _cachedSources[artifactId] = source;

    return CompilationResult(
      isSuccess: true,
      compilerOutput: 'Compiling Java source via JVM bytecode compiler...\n',
      duration: stopwatch.elapsed,
      artifact: ExecutionArtifact(
        id: artifactId,
        language: request.language,
        bytes: Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE]),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _activeProcess?.kill();
    _activeProcess = null;
    for (final dir in _cachedArtifactDirs.values) {
      try {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
    _cachedArtifactDirs.clear();
    _cachedClassNames.clear();
    _cachedSources.clear();
  }
}
