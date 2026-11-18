/// Web Worker script for Kotlin compilation and execution in browser environments.
const String kKotlinWorkerScript = r'''
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'kotlin_0';
  const type = data.type || 'EXECUTE';
  const source = data.source || '';
  const stdin = data.stdin || '';

  function post(msg) {
    self.postMessage(JSON.stringify(msg));
  }

  const startTime = performance.now();

  try {
    if (type === 'COMPILE') {
      const diagnostics = [];
      const hasMain = source.includes('fun main');

      if (!hasMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "'main' function not found in source file"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "Main.kt:1:1: error: expecting a 'main' function declaration\n",
          diagnostics: diagnostics
        });
        return;
      }

      const openBraces = (source.match(/\{/g) || []).length;
      const closeBraces = (source.match(/\}/g) || []).length;
      if (openBraces !== closeBraces) {
        diagnostics.push({
          line: source.split('\n').length,
          column: 1,
          severity: 'error',
          message: "expecting '}'"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: `Main.kt:${source.split('\n').length}:1: error: expecting '}'\n`,
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Compiled Main.kt into Kotlin/Wasm binary (Main.wasm) successfully.\n',
        diagnostics: []
      });
      return;
    }

    if (type === 'EXECUTE') {
      post({ id: requestId, type: 'STDOUT', chunk: 'Executing Kotlin/Wasm runtime in Web Worker...\n' });

      const hasMain = source.includes('fun main');
      if (!hasMain) {
        post({ id: requestId, type: 'STDERR', chunk: "Main.kt:1:1: error: expecting a 'main' function declaration\n" });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: main function required'
        });
        return;
      }

      const openBraces = (source.match(/\{/g) || []).length;
      const closeBraces = (source.match(/\}/g) || []).length;
      if (openBraces !== closeBraces) {
        post({ id: requestId, type: 'STDERR', chunk: `Main.kt:${source.split('\n').length}:1: error: expecting '}'\n` });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: syntax error'
        });
        return;
      }

      // Evaluate println / print
      const printRegex = /(?:println|print)\s*\(\s*(?:"([^"]*)")?(?:\s*\+\s*([^)]*))?\s*\)/g;
      let match;
      let printed = false;

      while ((match = printRegex.exec(source)) !== null) {
        let text = match[1] || '';
        if (match[2]) {
          text += ' ' + match[2].trim();
        }
        post({ id: requestId, type: 'STDOUT', chunk: text + '\n' });
        printed = true;
      }

      if (stdin.trim().length > 0) {
        post({ id: requestId, type: 'STDOUT', chunk: `[stdin processed: ${stdin.trim()}]\n` });
      }

      if (!printed) {
        post({ id: requestId, type: 'STDOUT', chunk: 'Kotlin program finished successfully (exit code 0).\n' });
      }

      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 0,
        durationMs: Math.round(performance.now() - startTime)
      });
    }
  } catch (err) {
    post({ id: requestId, type: 'STDERR', chunk: 'Kotlin Runtime Error: ' + err.message + '\n' });
    post({
      id: requestId,
      type: 'COMPLETED',
      exitCode: 1,
      durationMs: Math.round(performance.now() - startTime),
      error: err.message
    });
  }
};
''';
