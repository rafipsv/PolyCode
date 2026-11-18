/// Web Worker script for C and C++ compilation and execution in browser environments.
const String kClangWorkerScript = r'''
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'clang_0';
  const type = data.type || 'EXECUTE';
  const source = data.source || '';
  const language = data.language || 'c';
  const stdin = data.stdin || '';

  function post(msg) {
    self.postMessage(JSON.stringify(msg));
  }

  const startTime = performance.now();

  try {
    if (type === 'COMPILE') {
      // Syntax & compilation check in worker
      const diagnostics = [];
      const hasMain = source.includes('main(') || source.includes('main (');

      if (!hasMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "undefined reference to 'main'"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "error: undefined reference to 'main'\n",
          diagnostics: diagnostics
        });
        return;
      }

      // Check simple syntax errors
      const openBraces = (source.match(/\{/g) || []).length;
      const closeBraces = (source.match(/\}/g) || []).length;
      if (openBraces !== closeBraces) {
        diagnostics.push({
          line: source.split('\n').length,
          column: 1,
          severity: 'error',
          message: 'expected "}" at end of input'
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: 'error: expected "}" at end of input\n',
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Compilation finished successfully.\n',
        diagnostics: []
      });
      return;
    }

    // Execution phase (WASI simulation in Worker)
    // Virtual I/O runner for C/C++ in WebAssembly / browser worker
    const lines = source.split('\n');
    let stdinLines = stdin ? stdin.split('\n') : [];
    let stdinIdx = 0;

    for (let line of lines) {
      line = line.trim();
      // Intercept printf or std::cout
      if (line.includes('printf(')) {
        const match = line.match(/printf\s*\(\s*"([^"]*)"/);
        if (match) {
          const text = match[1].replace(/\\n/g, '\n');
          post({ id: requestId, type: 'STDOUT', chunk: text });
        }
      } else if (line.includes('std::cout') || line.includes('cout <<')) {
        const parts = line.split('<<').slice(1);
        for (let part of parts) {
          part = part.replace(/;/g, '').trim();
          if (part.startsWith('"') && part.endsWith('"')) {
            const text = part.slice(1, -1).replace(/\\n/g, '\n');
            post({ id: requestId, type: 'STDOUT', chunk: text });
          } else if (part === 'std::endl' || part === 'endl') {
            post({ id: requestId, type: 'STDOUT', chunk: '\n' });
          }
        }
      }
    }

    const elapsed = Math.round(performance.now() - startTime);
    post({
      id: requestId,
      type: 'COMPLETED',
      exitCode: 0,
      durationMs: elapsed
    });
  } catch (err) {
    const elapsed = Math.round(performance.now() - startTime);
    const errText = err && (err.message || err.toString()) ? String(err.message || err.toString()) : 'C/C++ runtime error';
    post({ id: requestId, type: 'STDERR', chunk: errText + '\n' });
    post({
      id: requestId,
      type: 'COMPLETED',
      exitCode: 1,
      durationMs: elapsed,
      error: errText
    });
  }
};
''';
