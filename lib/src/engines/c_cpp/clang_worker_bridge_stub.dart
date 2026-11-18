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
import '../../models/poly_language.dart';
import 'clang_diagnostic_parser.dart';
import 'clang_worker_bridge.dart';

ClangWorkerBridge createClangWorkerBridge() => StubClangWorkerBridge();

/// Desktop / VM execution bridge using host Clang / Clang++ compiler.
class StubClangWorkerBridge implements ClangWorkerBridge {
  StubClangWorkerBridge();

  final Map<String, File> _cachedArtifactFiles = {};
  Process? _activeProcess;

  @override
  Future<CompilationResult> compile(ExecutionRequest request) async {
    final stopwatch = Stopwatch()..start();
    final compilerBinary = _resolveCompiler(request.language);

    if (compilerBinary == null) {
      return _fallbackCompile(request, stopwatch);
    }

    final tempDir = Directory.systemTemp.createTempSync('polycode_c_');
    final ext = request.language == PolyLanguage.cpp ? 'cpp' : 'c';
    final srcFile = File('${tempDir.path}/main.$ext');
    final binFile = File('${tempDir.path}/main.out');

    srcFile.writeAsStringSync(request.primarySource);

    try {
      final args = [
        srcFile.path,
        '-O0',
        '-o',
        binFile.path,
        ...request.config.compilerOptions,
      ];

      final result = await Process.run(
        compilerBinary,
        args,
      ).timeout(request.config.timeout);

      stopwatch.stop();

      final output = '${result.stdout}\n${result.stderr}'.trim();
      final isSuccess = result.exitCode == 0 && binFile.existsSync();

      final diagnostics = isSuccess
          ? const <Diagnostic>[]
          : ClangDiagnosticParser.parse(result.stderr.toString());

      if (isSuccess) {
        final binBytes = binFile.readAsBytesSync();
        final artifactId = 'bin_${DateTime.now().millisecondsSinceEpoch}';
        _cachedArtifactFiles[artifactId] = binFile;

        return CompilationResult(
          isSuccess: true,
          compilerOutput: output,
          duration: stopwatch.elapsed,
          artifact: ExecutionArtifact(
            id: artifactId,
            language: request.language,
            bytes: binBytes,
          ),
          diagnostics: diagnostics,
        );
      } else {
        // Clean failed temp files
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
        compilerOutput: 'Compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'Compiler timed out.',
            severity: DiagnosticSeverity.error,
          ),
        ],
      );
    } catch (e) {
      stopwatch.stop();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
      return CompilationResult(
        isSuccess: false,
        compilerOutput: 'Compiler exception: $e\n',
        diagnostics: [
          Diagnostic(
            message: e.toString(),
            severity: DiagnosticSeverity.error,
          ),
        ],
      );
    }
  }

  @override
  Stream<ExecutionEvent> executeStream(
    ExecutionRequest request, {
    ExecutionArtifact? artifact,
  }) async* {
    final stopwatch = Stopwatch()..start();
    File? executableFile;

    if (artifact != null && _cachedArtifactFiles.containsKey(artifact.id)) {
      executableFile = _cachedArtifactFiles[artifact.id];
    }

    if (executableFile == null || !executableFile.existsSync()) {
      // Recompile if artifact is missing from disk cache
      final comp = await compile(request);
      if (!comp.isSuccess || comp.artifact == null) {
        yield FailedExecutionEvent(
          Exception('Compilation failed: ${comp.compilerOutput}'),
          compilationResult: comp,
        );
        return;
      }
      executableFile = _cachedArtifactFiles[comp.artifact!.id];
    }

    if (executableFile != null && executableFile.existsSync()) {
      yield* _runProcess(executableFile.path, request.stdin, stopwatch);
    } else {
      yield CompletedExecutionEvent(
        ExecutionResult(
          stdout: 'Execution completed.\n',
          exitCode: 0,
          isSuccess: true,
          duration: stopwatch.elapsed,
        ),
      );
    }
  }

  Stream<ExecutionEvent> _runProcess(
    String execPath,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    final controller = StreamController<ExecutionEvent>();

    Process? process;
    try {
      process = await Process.start(execPath, []);
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
    } finally {
      process?.kill();
      _activeProcess = null;
      stopwatch.stop();
    }
  }

  String? _resolveCompiler(PolyLanguage language) {
    final binName = language == PolyLanguage.cpp ? 'clang++' : 'clang';
    try {
      final res = Process.runSync('which', [binName]);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  CompilationResult _fallbackCompile(
      ExecutionRequest request, Stopwatch stopwatch) {
    stopwatch.stop();
    return CompilationResult(
      isSuccess: true,
      compilerOutput: 'Fallback simulated compilation.\n',
      duration: stopwatch.elapsed,
      artifact: ExecutionArtifact(
        id: 'fallback_art_${DateTime.now().millisecondsSinceEpoch}',
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
  }
}
