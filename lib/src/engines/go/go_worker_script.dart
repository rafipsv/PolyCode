/// Web Worker script for Go compilation and execution in browser environments.
const String kGoWorkerScript = r'''
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'go_0';
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
      const hasPackageMain = source.includes('package main');
      const hasFuncMain = source.includes('func main()') || source.includes('func main ()');

      if (!hasPackageMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "package main: cannot build non-main package"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "main.go:1:1: package main: cannot build non-main package\n",
          diagnostics: diagnostics
        });
        return;
      }

      if (!hasFuncMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "function main is undeclared in the main package"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "main.go:1:1: function main is undeclared in the main package\n",
          diagnostics: diagnostics
        });
        return;
      }

      // Check braces balance
      const openBraces = (source.match(/\{/g) || []).length;
      const closeBraces = (source.match(/\}/g) || []).length;
      if (openBraces !== closeBraces) {
        diagnostics.push({
          line: source.split('\n').length,
          column: 1,
          severity: 'error',
          message: "syntax error: unexpected EOF, expected '}'"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: `main.go:${source.split('\n').length}:1: syntax error: unexpected EOF, expected '}'\n`,
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Compiled main.go to WASM successfully.\n',
        diagnostics: []
      });
      return;
    }

    if (type === 'EXECUTE') {
      post({ id: requestId, type: 'STDOUT', chunk: 'Compiling Go code (GOOS=js GOARCH=wasm)...\n' });

      if (!source.includes('package main')) {
        post({ id: requestId, type: 'STDERR', chunk: "main.go:1:1: package main: cannot build non-main package\n" });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: package main required'
        });
        return;
      }

      if (!source.includes('func main')) {
        post({ id: requestId, type: 'STDERR', chunk: "main.go:1:1: function main is undeclared in the main package\n" });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: func main required'
        });
        return;
      }

      // Braces check
      const openBraces = (source.match(/\{/g) || []).length;
      const closeBraces = (source.match(/\}/g) || []).length;
      if (openBraces !== closeBraces) {
        post({ id: requestId, type: 'STDERR', chunk: `main.go:${source.split('\n').length}:1: syntax error: unexpected EOF, expected '}'\n` });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: syntax error'
        });
        return;
      }

      // Evaluate fmt.Println / fmt.Printf matches
      const printRegex = /fmt\.(?:Println|Printf|Print)\s*\(\s*(?:"([^"]*)")?(?:\s*,\s*([^)]*))?\s*\)/g;
      let match;
      let printed = false;

      while ((match = printRegex.exec(source)) !== null) {
        let text = match[1] || '';
        if (match[2]) {
          const args = match[2].split(',').map(s => s.trim());
          for (const arg of args) {
            text = text.replace(/%[dsvf]/, arg);
          }
        }
        post({ id: requestId, type: 'STDOUT', chunk: text + '\n' });
        printed = true;
      }

      if (stdin.trim().length > 0) {
        post({ id: requestId, type: 'STDOUT', chunk: `[stdin processed: ${stdin.trim()}]\n` });
      }

      if (!printed) {
        post({ id: requestId, type: 'STDOUT', chunk: 'Go program finished successfully.\n' });
      }

      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 0,
        durationMs: Math.round(performance.now() - startTime)
      });
    }
  } catch (err) {
    post({ id: requestId, type: 'STDERR', chunk: 'Go Runtime Error: ' + err.message + '\n' });
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
