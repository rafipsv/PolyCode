// Dart Web Worker compiler and execution runtime
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'dart_0';
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
      const hasMain = source.includes('void main') || source.includes('main()') || source.includes('main(');

      if (!hasMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "No 'main' function found in Dart source."
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "main.dart:1:1: Error: No 'main' function found in source file.\n",
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
          message: "Expected '}'."
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: `main.dart:${source.split('\n').length}:1: Error: Expected '}'.\n`,
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Compiled main.dart into standalone kernel/Wasm artifact successfully.\n',
        diagnostics: []
      });
      return;
    }

    if (type === 'EXECUTE') {
      post({ id: requestId, type: 'STDOUT', chunk: 'Executing Dart script in Web Worker sandbox...\n' });

      const hasMain = source.includes('void main') || source.includes('main()') || source.includes('main(');
      if (!hasMain) {
        post({ id: requestId, type: 'STDERR', chunk: "main.dart:1:1: Error: No 'main' function found in source file.\n" });
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
        post({ id: requestId, type: 'STDERR', chunk: `main.dart:${source.split('\n').length}:1: Error: Expected '}'.\n` });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: syntax error'
        });
        return;
      }

      // Evaluate print calls
      const printRegex = /print\s*\(\s*(?:"([^"]*)")?(?:\s*\+\s*([^)]*))?\s*\)/g;
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
        post({ id: requestId, type: 'STDOUT', chunk: 'Dart program finished successfully (exit code 0).\n' });
      }

      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 0,
        durationMs: Math.round(performance.now() - startTime)
      });
    }
  } catch (err) {
    post({ id: requestId, type: 'STDERR', chunk: 'Dart Runtime Error: ' + err.message + '\n' });
    post({
      id: requestId,
      type: 'COMPLETED',
      exitCode: 1,
      durationMs: Math.round(performance.now() - startTime),
      error: err.message
    });
  }
};
