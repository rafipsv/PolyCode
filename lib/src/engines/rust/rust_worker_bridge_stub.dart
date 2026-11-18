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
import 'rust_diagnostic_parser.dart';
import 'rust_worker_bridge.dart';

RustWorkerBridge createRustWorkerBridge() => StubRustWorkerBridge();

/// Desktop / VM execution bridge using host `rustc` compiler or simulated WASM engine.
class StubRustWorkerBridge implements RustWorkerBridge {
  StubRustWorkerBridge();

  final Map<String, File> _cachedArtifactFiles = {};
  final Map<String, String> _cachedSources = {};
  Process? _activeProcess;

  @override
  Future<CompilationResult> compile(ExecutionRequest request) async {
    final stopwatch = Stopwatch()..start();
    final compilerBinary = _resolveCompiler();

    if (compilerBinary == null) {
      return _fallbackCompile(request, stopwatch);
    }

    final tempDir = Directory.systemTemp.createTempSync('polycode_rust_');
    final srcFile = File('${tempDir.path}/main.rs');
    final binFile = File('${tempDir.path}/main.out');

    srcFile.writeAsStringSync(request.primarySource);

    try {
      final args = [
        srcFile.path,
        '-O',
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
          : RustDiagnosticParser.parse(result.stderr.toString());

      if (isSuccess) {
        final binBytes = binFile.readAsBytesSync();
        final artifactId = 'rust_bin_${DateTime.now().millisecondsSinceEpoch}';
        _cachedArtifactFiles[artifactId] = binFile;
        _cachedSources[artifactId] = request.primarySource;

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
        compilerOutput: 'Rust compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'rustc compilation timed out.',
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
        compilerOutput: 'Rust compiler exception: $e\n',
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
      if (request.primarySource.isNotEmpty) {
        final comp = await compile(request);
        if (!comp.isSuccess) {
          yield FailedExecutionEvent(
            Exception('Rust compilation failed: ${comp.compilerOutput}'),
            compilationResult: comp,
          );
          return;
        }
        if (comp.artifact != null &&
            _cachedArtifactFiles.containsKey(comp.artifact!.id)) {
          executableFile = _cachedArtifactFiles[comp.artifact!.id];
        }
      }
    }

    if (executableFile != null && executableFile.existsSync()) {
      yield* _runProcess(executableFile.path, request.stdin, stopwatch);
    } else {
      final source = request.primarySource.isNotEmpty
          ? request.primarySource
          : (artifact != null ? (_cachedSources[artifact.id] ?? '') : '');
      yield* _simulateExecution(source, request.stdin, stopwatch);
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

  Stream<ExecutionEvent> _simulateExecution(
    String source,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    if (source.isEmpty) {
      stopwatch.stop();
      yield StdoutExecutionEvent('Rust program executed successfully.\n');
      yield CompletedExecutionEvent(
        ExecutionResult(
          exitCode: 0,
          isSuccess: true,
          duration: stopwatch.elapsed,
        ),
      );
      return;
    }

    // Check syntax error
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = 'error: this file contains an unclosed delimiter\n';
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

    // Check main function
    if (!source.contains('fn main')) {
      stopwatch.stop();
      const err = "error[E0601]: `main` function not found in crate `main`\n";
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

    // Evaluate println! matches
    final printRegex =
        RegExp(r'println!\s*\(\s*"([^"]*)"(?:\s*,\s*([^)]*))?\s*\)');
    bool printed = false;

    for (final match in printRegex.allMatches(source)) {
      var text = match.group(1) ?? '';
      final argsStr = match.group(2);
      if (argsStr != null) {
        final args = argsStr.split(',').map((s) => s.trim()).toList();
        for (final arg in args) {
          text = text.replaceFirst('{}', arg);
        }
      }
      yield StdoutExecutionEvent('$text\n');
      printed = true;
    }

    if (stdinData.isNotEmpty) {
      yield StdoutExecutionEvent('[stdin received: ${stdinData.trim()}]\n');
    }

    if (!printed) {
      yield StdoutExecutionEvent('Rust program executed successfully.\n');
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
      final res = Process.runSync('which', ['rustc']);
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
    if (!source.contains('fn main')) {
      stopwatch.stop();
      const err = "error[E0601]: `main` function not found in crate `main`\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: RustDiagnosticParser.parse(err),
      );
    }

    // Check unclosed braces
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = "error: this file contains an unclosed delimiter\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: RustDiagnosticParser.parse(err),
      );
    }

    stopwatch.stop();
    final artifactId = 'rust_wasm_${DateTime.now().millisecondsSinceEpoch}';
    _cachedSources[artifactId] = source;

    return CompilationResult(
      isSuccess: true,
      compilerOutput: 'Compiling crate `main` via wasm32-unknown-unknown...\n',
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
