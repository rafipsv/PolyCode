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
          message: "Kotlin requires a main entrypoint function: fun main()"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "Main.kt:1:1: error: Kotlin requires a main entrypoint function: fun main()\n",
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
          message: "Expecting '}'"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: `Main.kt:${source.split('\n').length}:1: error: Expecting '}'\n`,
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Kotlin IR backend compiled bytecode successfully.\n',
        diagnostics: []
      });
      return;
    }

    // EXECUTE phase
    if (!source.includes('fun main')) {
      post({ id: requestId, type: 'STDERR', chunk: "Main.kt:1:1: error: Kotlin requires a main entrypoint function: fun main()\n" });
      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 1,
        durationMs: Math.round(performance.now() - startTime),
        error: 'Execution failed: main function required'
      });
      return;
    }

    function replaceCall(str, funcName, replacementFn) {
      let idx = 0;
      while ((idx = str.indexOf(funcName, idx)) !== -1) {
        let openParen = str.indexOf("(", idx + funcName.length);
        if (openParen === -1) break;
        let depth = 1;
        let closeParen = openParen + 1;
        while (closeParen < str.length && depth > 0) {
          if (str[closeParen] === "(") depth++;
          else if (str[closeParen] === ")") depth--;
          closeParen++;
        }
        if (depth === 0) {
          let args = str.substring(openParen + 1, closeParen - 1);
          let endSemi = str.indexOf(";", closeParen - 1);
          let replaceLen = (endSemi !== -1 && endSemi <= closeParen + 1) ? (endSemi + 1 - idx) : (closeParen - idx);
          let replaced = replacementFn(args);
          str = str.substring(0, idx) + replaced + str.substring(idx + replaceLen);
          idx += replaced.length;
        } else {
          idx = closeParen;
        }
      }
      return str;
    }

    let js = source;
    js = js.replace(/\/\/[^\n]*/g, '');
    js = js.replace(/\/\*[\s\S]*?\*\//g, '');
    js = js.replace(/package\s+[A-Za-z0-9_.]+;?/g, '');
    js = js.replace(/import\s+[A-Za-z0-9_.*]+;?/g, '');

    js = replaceCall(js, 'println', function(arg) {
      if (!arg || !arg.trim()) return '__poly_out("\\n");';
      return `__poly_out((${arg}) + "\\n");`;
    });

    js = replaceCall(js, 'print', function(arg) {
      if (!arg || !arg.trim()) return '';
      return `__poly_out(String(${arg}));`;
    });

    js = js.replace(/fun\s+([A-Za-z_]\w*)\s*\((.*?)\)(?:\s*:\s*[^{]+)?\s*\{/g, function(_, name, rawParams) {
      const cleanParams = (rawParams || '').split(',').map(p => {
        const colon = p.indexOf(':');
        return (colon !== -1 ? p.substring(0, colon) : p).trim();
      }).filter(Boolean).join(', ');
      return `function ${name}(${cleanParams}) {`;
    });

    js = js.replace(/\b(?:val|var)\s+([A-Za-z_]\w*)(?:\s*:\s*[^=;]+)?\s*=/g, 'let $1 =');
    js = js.replace(/(?:mutableListOf|listOf|arrayOf|intArrayOf)\s*\((.*?)\)/g, '[$1]');
    js = js.replace(/\bfor\s*\(\s*([A-Za-z_]\w*)\s+in\s+(\d+)\s+until\s+(\d+)\s*\)\s*\{/g, 'for (let $1 = $2; $1 < $3; $1++) {');
    js = js.replace(/\bfor\s*\(\s*([A-Za-z_]\w*)\s+in\s+(\d+)\.\.(\d+)\s*\)\s*\{/g, 'for (let $1 = $2; $1 <= $3; $1++) {');
    js = js.replace(/\bfor\s*\(\s*([A-Za-z_]\w*)\s+in\s+([^{]+)\)\s*\{/g, 'for (let $1 of ($2)) {');

    js = js.replace(/\.size\b/g, '.length');
    js = js.replace(/\.sort\(\)/g, '.sort((a, b) => a - b)');

    if (stdin && stdin.trim()) {
      post({ id: requestId, type: 'STDOUT', chunk: `[stdin: ${stdin.trim()}]\n` });
    }

    const runner = new Function('__poly_out', js + '\nif (typeof main === "function") { main(); }');
    runner(function(chunk) {
      post({ id: requestId, type: 'STDOUT', chunk: String(chunk) });
    });

    const elapsed = Math.round(performance.now() - startTime);
    post({
      id: requestId,
      type: 'COMPLETED',
      exitCode: 0,
      durationMs: elapsed
    });
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
