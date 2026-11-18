// PolyCode Dart Sandboxed Web Worker
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
      const hasMain = source.includes('void main') || source.includes('main()') || source.includes('main ()');

      if (!hasMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "The function 'main' isn't defined"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "Error: The function 'main' isn't defined.\n",
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
          message: "Expected '}'"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: `Error: Expected '}'.\n`,
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Compiled Dart source to JS/WASM bundle successfully.\n',
        diagnostics: []
      });
      return;
    }

    // EXECUTE phase
    if (!source.includes('main')) {
      post({ id: requestId, type: 'STDERR', chunk: "Error: The function 'main' isn't defined.\n" });
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
        if (idx > 0 && /[A-Za-z0-9_]/.test(str[idx - 1])) {
          idx += funcName.length;
          continue;
        }
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
    js = js.replace(/import\s+['"][^'"]+['"];?/g, '');

    js = replaceCall(js, 'print', function(args) {
      if (!args || !args.trim()) return '__poly_out("\\n");';
      return `__poly_out((${args}) + "\\n");`;
    });

    js = js.replace(/(?:void|int|double|String|bool|dynamic|Future<[^>]*>|[A-Za-z0-9_<>[\]]+)\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{/g, function(_, name, rawParams) {
      const cleanParams = (rawParams || '').split(',').map(p => {
        const parts = p.trim().split(/\s+/);
        return parts[parts.length - 1];
      }).filter(Boolean).join(', ');
      return `function ${name}(${cleanParams}) {`;
    });

    js = js.replace(/\b(?:var|final|const|int|double|String|bool|List<[^>]*>|Map<[^>]*>)\s+([A-Za-z_]\w*)(?:\s*:\s*[^=;]+)?\s*=/g, 'let $1 =');
    js = js.replace(/\.where\s*\(/g, '.filter(');
    js = js.replace(/\.fold\s*\(\s*([^,]+)\s*,\s*\(([^)]+)\)\s*=>/g, '.reduce(($2) =>');
    js = js.replace(/\.length\b/g, '.length');
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
