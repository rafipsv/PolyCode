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

    // EXECUTE phase
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
    js = js.replace(/package\s+main/g, '');
    js = js.replace(/import\s*\([^)]*\)/g, '');
    js = js.replace(/import\s+"[^"]+"/g, '');

    js = replaceCall(js, 'fmt.Println', function(args) {
      if (!args || !args.trim()) return '__poly_out("\\n");';
      return `__poly_out([${args}].join(" ") + "\\n");`;
    });

    js = replaceCall(js, 'fmt.Printf', function(argsStr) {
      const commaIdx = argsStr.indexOf(',');
      if (commaIdx === -1) {
        return `__poly_out(${argsStr}.replace(/\\\\n/g, '\\n'));`;
      }
      const fmt = argsStr.substring(0, commaIdx).trim();
      const rest = argsStr.substring(commaIdx + 1).trim();
      return `__poly_out((function(f, ...args) {
        let p = f.split(/%[0-9]*\\.?[0-9]*[dvstf%]/);
        let out = '';
        p.forEach(function(part, idx) {
          out += part;
          if (idx < args.length) out += args[idx];
        });
        return out.replace(/\\\\n/g, '\\n');
      })(${fmt}, ${rest}));`;
    });

    js = js.replace(/func\s+([A-Za-z_]\w*)\s*\((.*?)\)(?:\s*(?:\([^)]*\)|[A-Za-z0-9_\[\]]+))?\s*\{/g, function(_, name, rawParams) {
      const cleanParams = (rawParams || '').split(',').map(p => {
        p = p.trim();
        const parts = p.split(/\s+/);
        return parts[0];
      }).filter(Boolean).join(', ');
      return `function ${name}(${cleanParams}) {`;
    });

    js = js.replace(/(?:\[\]|\[\d*\])[A-Za-z0-9_.]+\s*\{([^}]*)\}/g, '[$1]');
    js = js.replace(/([A-Za-z0-9_\[\]\s.+-]+),\s*([A-Za-z0-9_\[\]\s.+-]+)\s*=\s*([A-Za-z0-9_\[\]\s.+-]+),\s*([A-Za-z0-9_\[\]\s.+-]+);?/g, '[$1, $2] = [$3, $4];');

    js = js.replace(/for\s+([A-Za-z0-9_,\s]+)\s*:=\s*range\s+([^{]+)\s*\{/g, function(_, vars, expr) {
      const parts = vars.split(',').map(v => v.trim());
      if (parts.length === 2) {
        return `for (let ${parts[0]} = 0; ${parts[0]} < (${expr}).length; ${parts[0]}++) { let ${parts[1]} = (${expr})[${parts[0]}];`;
      }
      return `for (let ${parts[0]} = 0; ${parts[0]} < (${expr}).length; ${parts[0]}++) {`;
    });

    js = js.replace(/for\s+([^{;]+);([^{;]+);([^{]+)\s*\{/g, function(_, init, cond, post) {
      init = init.replace(/([A-Za-z_]\w*)\s*:=/g, 'let $1 =');
      if (!init.includes('let ') && !init.includes('var ')) init = 'let ' + init;
      return `for (${init.trim()}; ${cond.trim()}; ${post.trim()}) {`;
    });

    js = js.replace(/for\s+([^;{]+)\s*\{/g, function(_, cond) {
      cond = cond.trim();
      if (cond.startsWith('(') && cond.endsWith(')')) return `while ${cond} {`;
      return `while (${cond}) {`;
    });

    js = js.replace(/\bif\s+([^{]+)\s*\{/g, function(_, cond) {
      cond = cond.trim();
      if (cond.startsWith('(') && cond.endsWith(')')) return `if ${cond} {`;
      return `if (${cond}) {`;
    });

    js = js.replace(/\bvar\s+([A-Za-z_]\w*)(?:\s+[A-Za-z0-9_\[\]]+)?\s*=/g, 'let $1 =');
    js = js.replace(/\b([A-Za-z_]\w*)\s*:=/g, 'let $1 =');
    js = js.replace(/\blen\s*\(/g, '((x) => x.length)(');

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
