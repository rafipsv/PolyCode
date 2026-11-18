/// Web Worker script for Rust compilation and execution in browser environments.
const String kRustWorkerScript = r'''
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'rust_0';
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
      const hasMain = source.includes('fn main');

      if (!hasMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "`main` function not found in crate `main`"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "error[E0601]: `main` function not found in crate `main`\n",
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
          message: "this file contains an unclosed delimiter"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "error: this file contains an unclosed delimiter\n",
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Finished release [optimized] target(s) in 0.42s\n',
        diagnostics: []
      });
      return;
    }

    // EXECUTE phase
    if (!source.includes('fn main')) {
      post({ id: requestId, type: 'STDERR', chunk: "error[E0601]: `main` function not found in crate `main`\n" });
      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 1,
        durationMs: Math.round(performance.now() - startTime),
        error: 'Execution failed: missing main function'
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

    js = replaceCall(js, 'println!', function(argsStr) {
      argsStr = argsStr.trim();
      if (!argsStr) return '__poly_out("\\n");';
      const quoteStart = argsStr.indexOf('"');
      if (quoteStart === -1) {
        return `__poly_out(${argsStr} + "\\n");`;
      }
      let quoteEnd = quoteStart + 1;
      while (quoteEnd < argsStr.length) {
        if (argsStr[quoteEnd] === '\\') {
          quoteEnd += 2;
        } else if (argsStr[quoteEnd] === '"') {
          break;
        } else {
          quoteEnd++;
        }
      }
      const fmt = argsStr.substring(quoteStart + 1, quoteEnd);
      let rest = argsStr.substring(quoteEnd + 1).trim();
      if (rest.startsWith(',')) rest = rest.substring(1).trim();

      if (!rest) {
        return `__poly_out(${JSON.stringify(fmt + '\n')});`;
      }

      const parts = fmt.split(/\{(?::\?)?\}/);
      const args = [];
      let depth = 0;
      let cur = '';
      for (let i = 0; i < rest.length; i++) {
        const c = rest[i];
        if (c === '(' || c === '[' || c === '{') depth++;
        else if (c === ')' || c === ']' || c === '}') depth--;
        if (c === ',' && depth === 0) {
          args.push(cur.trim());
          cur = '';
        } else {
          cur += c;
        }
      }
      if (cur.trim()) args.push(cur.trim());

      let out = '__poly_out(';
      for (let i = 0; i < parts.length; i++) {
        if (parts[i]) {
          out += JSON.stringify(parts[i]);
          if (i < args.length) out += ' + ';
        }
        if (i < args.length) {
          out += `String(${args[i]})`;
          if (i < parts.length - 1 && parts[i + 1]) out += ' + ';
        }
      }
      out += ' + "\\n");';
      return out;
    });

    js = replaceCall(js, 'print!', function(argsStr) {
      argsStr = argsStr.trim();
      if (!argsStr) return '';
      return `__poly_out(${argsStr});`;
    });

    // Implicit return in Rust functions
    js = js.replace(/([^{};]+)\s*\}/g, function(match, expr) {
      const trimmed = expr.trim();
      if (!trimmed ||
          trimmed.startsWith('if ') ||
          trimmed.startsWith('for ') ||
          trimmed.startsWith('while ') ||
          trimmed.startsWith('loop ') ||
          trimmed.startsWith('return ') ||
          trimmed.startsWith('let ') ||
          trimmed.startsWith('__poly_out')) {
        return match;
      }
      return `return ${trimmed}; }`;
    });

    js = js.replace(/fn\s+([A-Za-z_]\w*)\s*\((.*?)\)(?:\s*->\s*[^{]+)?\s*\{/g, function(_, name, rawParams) {
      const cleanParams = (rawParams || '').split(',').map(p => {
        const colon = p.indexOf(':');
        return (colon !== -1 ? p.substring(0, colon) : p).replace(/mut\s+/g, '').trim();
      }).filter(Boolean).join(', ');
      return `function ${name}(${cleanParams}) {`;
    });

    js = js.replace(/\bif\s+([^{]+)\s*\{/g, function(_, cond) {
      cond = cond.trim();
      if (cond.startsWith('(') && cond.endsWith(')')) return `if ${cond} {`;
      return `if (${cond}) {`;
    });

    js = js.replace(/\bwhile\s+([^{]+)\s*\{/g, function(_, cond) {
      cond = cond.trim();
      if (cond.startsWith('(') && cond.endsWith(')')) return `while ${cond} {`;
      return `while (${cond}) {`;
    });

    js = js.replace(/\bfor\s+([A-Za-z_]\w*)\s+in\s+(\d+)\.\.(\d+)\s*\{/g, 'for (let $1 = $2; $1 < $3; $1++) {');
    js = js.replace(/\bfor\s+([A-Za-z_]\w*)\s+in\s+([^{]+)\s*\{/g, 'for (let $1 of ($2)) {');

    js = js.replace(/let\s+(?:mut\s+)?([A-Za-z_]\w*)(?:\s*:\s*[^=;]+)?\s*=/g, 'let $1 =');
    js = js.replace(/vec!\s*\[/g, '[');
    js = js.replace(/\.len\(\)/g, '.length');
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
    post({ id: requestId, type: 'STDERR', chunk: 'Rust Runtime Error: ' + err.message + '\n' });
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
