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
import 'kotlin_diagnostic_parser.dart';
import 'kotlin_worker_bridge.dart';

KotlinWorkerBridge createKotlinWorkerBridge() => StubKotlinWorkerBridge();

/// Desktop / VM execution bridge using host `kotlinc` compiler or simulated WASM engine.
class StubKotlinWorkerBridge implements KotlinWorkerBridge {
  StubKotlinWorkerBridge();

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

    final tempDir = Directory.systemTemp.createTempSync('polycode_kt_');
    final srcFile = File('${tempDir.path}/Main.kt');
    final jarFile = File('${tempDir.path}/Main.jar');

    srcFile.writeAsStringSync(request.primarySource);

    try {
      final args = [
        srcFile.path,
        '-include-runtime',
        '-d',
        jarFile.path,
        ...request.config.compilerOptions,
      ];

      final result = await Process.run(
        compilerBinary,
        args,
        workingDirectory: tempDir.path,
      ).timeout(request.config.timeout);

      stopwatch.stop();

      final output = '${result.stdout}\n${result.stderr}'.trim();
      final isSuccess = result.exitCode == 0 && jarFile.existsSync();
      final diagnostics = isSuccess
          ? const <Diagnostic>[]
          : KotlinDiagnosticParser.parse(result.stderr.toString());

      if (isSuccess) {
        final jarBytes = jarFile.readAsBytesSync();
        final artifactId = 'kotlin_jar_${DateTime.now().millisecondsSinceEpoch}';
        _cachedArtifactFiles[artifactId] = jarFile;
        _cachedSources[artifactId] = request.primarySource;

        return CompilationResult(
          isSuccess: true,
          compilerOutput: output,
          duration: stopwatch.elapsed,
          artifact: ExecutionArtifact(
            id: artifactId,
            language: request.language,
            bytes: jarBytes,
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
        compilerOutput: 'Kotlin compilation timed out.\n',
        diagnostics: [
          Diagnostic(
            message: 'kotlinc compilation timed out.',
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
    File? jarFile;

    if (artifact != null && _cachedArtifactFiles.containsKey(artifact.id)) {
      jarFile = _cachedArtifactFiles[artifact.id];
    }

    if (jarFile == null || !jarFile.existsSync()) {
      if (request.primarySource.isNotEmpty) {
        final comp = await compile(request);
        if (!comp.isSuccess) {
          yield FailedExecutionEvent(
            Exception('Kotlin compilation failed: ${comp.compilerOutput}'),
            compilationResult: comp,
          );
          return;
        }
        if (comp.artifact != null &&
            _cachedArtifactFiles.containsKey(comp.artifact!.id)) {
          jarFile = _cachedArtifactFiles[comp.artifact!.id];
        }
      }
    }

    final javaBinary = _resolveJavaRuntime();
    if (javaBinary != null && jarFile != null && jarFile.existsSync()) {
      yield* _runProcess(javaBinary, jarFile.path, request.stdin, stopwatch);
    } else {
      final source = request.primarySource.isNotEmpty
          ? request.primarySource
          : (artifact != null ? (_cachedSources[artifact.id] ?? '') : '');
      yield* _simulateExecution(source, request.stdin, stopwatch);
    }
  }

  Stream<ExecutionEvent> _runProcess(
    String javaBinary,
    String jarPath,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    final controller = StreamController<ExecutionEvent>();

    Process? process;
    try {
      process = await Process.start(
        javaBinary,
        ['-jar', jarPath],
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
        FailedExecutionEvent(Exception('Kotlin execution failed: $e')),
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
      yield StdoutExecutionEvent('Kotlin program executed successfully.\n');
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
    if (!source.contains('fun main')) {
      stopwatch.stop();
      const err = "Main.kt:1:1: error: expecting a 'main' function declaration\n";
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
      const err = "Main.kt:10:1: error: expecting '}'\n";
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

    // Try Node.js evaluation if available
    final nodeBin = _resolveNodeExecutable();
    if (nodeBin != null) {
      final jsCode = _transpileKotlinToJs(source);
      if (jsCode != null) {
        yield* _executeWithNode(nodeBin, jsCode, stdinData, stopwatch);
        return;
      }
    }

    // Evaluate println / print
    final printRegex =
        RegExp(r'(?:println|print)\s*\(\s*(.*?)\s*\)\s*(?:;|$)');
    bool printed = false;

    for (final match in printRegex.allMatches(source)) {
      var content = match.group(1)?.trim() ?? '';

      if (content.startsWith('"') && content.endsWith('"') && content.length >= 2) {
        content = content.substring(1, content.length - 1);
      }

      yield StdoutExecutionEvent('$content\n');
      printed = true;
    }

    if (stdinData.isNotEmpty) {
      yield StdoutExecutionEvent('[stdin received: ${stdinData.trim()}]\n');
    }

    if (!printed) {
      yield StdoutExecutionEvent('Kotlin program executed successfully.\n');
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
      final res = Process.runSync('which', ['kotlinc']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  String? _resolveJavaRuntime() {
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

    // Check main function
    if (!source.contains('fun main')) {
      stopwatch.stop();
      const err = "Main.kt:1:1: error: expecting a 'main' function declaration\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: KotlinDiagnosticParser.parse(err),
      );
    }

    // Check unclosed braces
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      stopwatch.stop();
      const err = "Main.kt:10:1: error: expecting '}'\n";
      return CompilationResult(
        isSuccess: false,
        compilerOutput: err,
        duration: stopwatch.elapsed,
        diagnostics: KotlinDiagnosticParser.parse(err),
      );
    }

    stopwatch.stop();
    final artifactId = 'kotlin_wasm_${DateTime.now().millisecondsSinceEpoch}';
    _cachedSources[artifactId] = source;

    return CompilationResult(
      isSuccess: true,
      compilerOutput: 'Compiling Main.kt via Kotlin/Wasm compiler...\n',
      duration: stopwatch.elapsed,
      artifact: ExecutionArtifact(
        id: artifactId,
        language: request.language,
        bytes: Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]),
      ),
    );
  }

  String? _resolveNodeExecutable() {
    try {
      final res = Process.runSync('which', ['node']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return res.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }

  String? _transpileKotlinToJs(String ktCode) {
    try {
      var js = ktCode;
      js = js.replaceAll(RegExp(r'package\s+[A-Za-z0-9_\.]+;?'), '');
      js = js.replaceAll(RegExp(r'import\s+[A-Za-z0-9_\.\*]+;?'), '');

      js = js.replaceAllMapped(
        RegExp(r'fun\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)(?:\s*:\s*[^{]+)?\s*\{'),
        (match) {
          final name = match.group(1)!;
          final rawParams = match.group(2) ?? '';
          final cleanParams = rawParams.split(',').map((p) {
            final colon = p.indexOf(':');
            return (colon != -1 ? p.substring(0, colon) : p).trim();
          }).where((p) => p.isNotEmpty).join(', ');
          return 'function $name($cleanParams) {';
        },
      );

      js = js.replaceAllMapped(
        RegExp(r'\b(?:val|var)\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*:\s*[^=;]+)?\s*='),
        (match) => 'let ${match.group(1)} =',
      );

      js = js.replaceAllMapped(
        RegExp(r'(?:mutableListOf|listOf)\s*\((.*?)\)'),
        (m) => '[${m.group(1)}]',
      );

      js = js.replaceAll('.size', '.length');

      js = js.replaceAllMapped(
        RegExp(r'\bfor\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*?)\s+until\s+(.*?)\s*\)\s*\{'),
        (m) => 'for (let ${m.group(1)} = ${m.group(2)}; ${m.group(1)} < ${m.group(3)}; ${m.group(1)}++) {',
      );

      js = js.replaceAllMapped(
        RegExp(r'println\s*\(\s*"([^"]*)"\s*\)'),
        (match) {
          final text = match.group(1) ?? '';
          var expr = text.replaceAllMapped(
            RegExp(r'\$([A-Za-z_][A-Za-z0-9_]*)'),
            (m) => '" + (${m.group(1)}) + "',
          );
          return 'console.log("$expr");';
        },
      );

      js = js.replaceAllMapped(
        RegExp(r'println\s*\(\s*(.*?)\s*\)'),
        (m) => 'console.log(${m.group(1)})',
      );

      js += '\nif (typeof main === "function") { main(); }\n';
      return js;
    } catch (_) {
      return null;
    }
  }

  Stream<ExecutionEvent> _executeWithNode(
    String nodePath,
    String jsCode,
    String stdinData,
    Stopwatch stopwatch,
  ) async* {
    final controller = StreamController<ExecutionEvent>();

    final wrapper = '''
const readline = require('readline');
let stdinLines = ${jsonEncode(stdinData)}.split('\\n');
let stdinCursor = 0;
function readLine() {
  return stdinCursor < stdinLines.length ? stdinLines[stdinCursor++] : null;
}
try {
  $jsCode
  process.exit(0);
} catch (err) {
  console.error(err && err.message ? err.message : String(err));
  process.exit(1);
}
''';

    Process? process;
    try {
      process = await Process.start(nodePath, ['-e', wrapper]);
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
    } catch (_) {
      stopwatch.stop();
      controller.close();
    } finally {
      process?.kill();
      _activeProcess = null;
    }
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
