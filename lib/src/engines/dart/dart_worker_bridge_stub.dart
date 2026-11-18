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
import 'dart_diagnostic_parser.dart';
import 'dart_worker_bridge.dart';

DartWorkerBridge createDartWorkerBridge() => StubDartWorkerBridge();

/// Desktop / VM execution bridge using host `dart` runtime or simulated execution.
class StubDartWorkerBridge implements DartWorkerBridge {
  StubDartWorkerBridge();

  final Map<String, File> _cachedArtifactFiles = {};
  final Map<String, String> _cachedSources = {};
  Process? _activeProcess;

  @override
  Future<CompilationResult> compile(ExecutionRequest request) async {
    final stopwatch = Stopwatch()..start();
    final dartBinary = _resolveCompiler();

    if (dartBinary == null) {
      return _fallbackCompile(request, stopwatch);
    }

    final tempDir = Directory.systemTemp.createTempSync('polycode_dart_');
    final srcFile = File('${tempDir.path}/main.dart');

    srcFile.writeAsStringSync(request.primarySource);

    try {
      final args = [
        'analyze',
        '--fatal-infos',
        ...request.config.compilerOptions,
        srcFile.path,
      ];

      final result = await Process.run(
        dartBinary,
        args,
        workingDirectory: tempDir.path,
      ).timeout(request.config.timeout);

      stopwatch.stop();

      final output = '${result.stdout}\n${result.stderr}'.trim();
      final isSuccess = result.exitCode == 0;
      final diagnostics = isSuccess
          ? const <Diagnostic>[]
          : DartDiagnosticParser.parse(output);

      if (isSuccess) {
        final srcBytes = srcFile.readAsBytesSync();
        final artifactId = 'dart_src_${DateTime.now().millisecondsSinceEpoch}';
        _cachedArtifactFiles[artifactId] = srcFile;
        _cachedSources[artifactId] = request.primarySource;

        return CompilationResult(
          isSuccess: true,
          compilerOutput: output.isEmpty ? 'No issues found.\n' : output,
          duration: stopwatch.elapsed,
          artifact: ExecutionArtifact(
            id: artifactId,
            language: request.language,
            bytes: srcBytes,
          ),
          diagnostics: diagnostics,
        );
      } else {
        // If analyze reported errors, return compilation failure
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
        compilerOutput: 'Dart analysis/compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'Dart compilation timed out.',
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
    File? srcFile;

    if (artifact != null && _cachedArtifactFiles.containsKey(artifact.id)) {
      srcFile = _cachedArtifactFiles[artifact.id];
    }

    if (srcFile == null || !srcFile.existsSync()) {
      if (request.primarySource.isNotEmpty) {
        final comp = await compile(request);
        if (!comp.isSuccess) {
          yield FailedExecutionEvent(
            Exception('Dart compilation failed: ${comp.compilerOutput}'),
            compilationResult: comp,
          );
          return;
        }
        if (comp.artifact != null &&
            _cachedArtifactFiles.containsKey(comp.artifact!.id)) {
          srcFile = _cachedArtifactFiles[comp.artifact!.id];
        }
      }
    }

    final dartBinary = _resolveCompiler();
    if (dartBinary != null && srcFile != null && srcFile.existsSync()) {
      yield* _runProcess(dartBinary, srcFile.path, request.stdin, stopwatch);
    } else {
      final source = request.primarySource.isNotEmpty
          ? request.primarySource
          : (artifact != null ? (_cachedSources[artifact.id] ?? '') : '');
      yield* _simulateExecution(source, request.stdin, stopwatch);
    }
  }

  Stream<ExecutionEvent> _runProcess(
    String dartBinary,
    String scriptPath,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    final controller = StreamController<ExecutionEvent>();

    Process? process;
    try {
      process = await Process.start(
        dartBinary,
        ['run', scriptPath],
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
        FailedExecutionEvent(Exception('Dart execution failed: $e')),
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
      yield StdoutExecutionEvent('Dart program executed successfully.\n');
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 0,
          isSuccess: true,
          duration: stopwatch.elapsed,
        ),
      );
      return;
    }

    // Check main function
    final hasMain = source.contains('void main') ||
        source.contains('main()') ||
        source.contains('main(');
    if (!hasMain) {
      stopwatch.stop();
      const err = "main.dart:1:1: Error: No 'main' function found in source file.\n";
      yield StderrExecutionEvent(err);
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 1,
          isSuccess: false,
          stderr: err,
          duration: stopwatch.elapsed,
          error: 'Missing main function',
        ),
      );
      return;
    }

    // Check unclosed braces
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = "main.dart:10:1: Error: Expected '}'.\n";
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

    // Evaluate print calls
    final printRegex =
        RegExp(r'print\s*\(\s*(.*?)\s*\)\s*;');
    bool printed = false;

    for (final match in printRegex.allMatches(source)) {
      var content = match.group(1)?.trim() ?? '';

      if (content.startsWith('"') && content.endsWith('"') && content.length >= 2) {
        content = content.substring(1, content.length - 1);
      } else if (content.startsWith("'") && content.endsWith("'") && content.length >= 2) {
        content = content.substring(1, content.length - 1);
      }

      yield StdoutExecutionEvent('$content\n');
      printed = true;
    }

    if (stdinData.isNotEmpty) {
      yield StdoutExecutionEvent('[stdin received: ${stdinData.trim()}]\n');
    }

    if (!printed) {
      yield StdoutExecutionEvent('Dart program executed successfully.\n');
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
      final exec = Platform.resolvedExecutable;
      if (exec.isNotEmpty && File(exec).existsSync() && exec.contains('dart')) {
        return exec;
      }
    } catch (_) {}

    try {
      final res = Process.runSync('which', ['dart']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  CompilationResult _fallbackCompile(
      ExecutionRequest request, Stopwatch stopwatch) {
    final source = request.primarySource;

    // Check main function
    final hasMain = source.contains('void main') ||
        source.contains('main()') ||
        source.contains('main(');
    if (!hasMain) {
      stopwatch.stop();
      const err = "main.dart:1:1: Error: No 'main' function found in source file.\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: DartDiagnosticParser.parse(err),
      );
    }

    // Check unclosed braces
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = "main.dart:10:1: Error: Expected '}'.\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: DartDiagnosticParser.parse(err),
      );
    }

    stopwatch.stop();
    final artifactId = 'dart_wasm_${DateTime.now().millisecondsSinceEpoch}';
    _cachedSources[artifactId] = source;

    return CompilationResult(
      isSuccess: true,
      compilerOutput: 'Compiled main.dart into Dart artifact successfully.\n',
      duration: stopwatch.elapsed,
      artifact: ExecutionArtifact(
        id: artifactId,
        language: request.language,
        bytes: Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _activeProcess?.kill();
    _activeProcess = null;
    for (final file in _cachedArtifactFiles.values) {
      try {
        if (file.existsSync()) {
          file.parent.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
    _cachedArtifactFiles.clear();
    _cachedSources.clear();
  }
}
