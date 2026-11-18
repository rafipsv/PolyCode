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
  const isCpp = language === 'cpp';

  function post(msg) {
    self.postMessage(JSON.stringify(msg));
  }

  const startTime = performance.now();

  try {
    if (type === 'COMPILE') {
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

    // EXECUTE phase
    if (!source.includes('main(') && !source.includes('main (')) {
      post({ id: requestId, type: 'STDERR', chunk: "error: undefined reference to 'main'\n" });
      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 1,
        durationMs: Math.round(performance.now() - startTime),
        error: "undefined reference to 'main'"
      });
      return;
    }

    function splitTopLevel(str, delimiter) {
      let res = [];
      let current = "";
      let depth = 0;
      for (let i = 0; i < str.length; i++) {
        let char = str[i];
        if (char === "(" || char === "{" || char === "[") depth++;
        else if (char === ")" || char === "}" || char === "]") depth--;
        if (depth === 0 && str.substr(i, delimiter.length) === delimiter) {
          res.push(current);
          current = "";
          i += delimiter.length - 1;
        } else {
          current += char;
        }
      }
      if (current.length > 0) res.push(current);
      return res;
    }

    let js = source;
    js = js.replace(/\/\*[\s\S]*?\*\//g, "");
    js = js.replace(/\/\/[^\n]*/g, "");
    js = js.replace(/#include\s*<[^>]+>/g, "");
    js = js.replace(/#include\s*"[^"]+"/g, "");
    js = js.replace(/using\s+namespace\s+std\s*;/g, "");

    if (isCpp) {
      js = js.replace(/std::/g, "");
    }

    js = js.replace(/struct\s+([A-Za-z_]\w*)\s*\{([^}]+)\};/g, function(_, name, body) {
      const fields = (body.match(/[A-Za-z_]\w*(?=\s*;)/g) || []);
      return `function ${name}(${fields.join(", ")}) { ${fields.map(f => `this.${f} = ${f};`).join(" ")} }`;
    });

    js = js.replace(/\([A-Za-z_*\s]+\)?\s*malloc\s*\([^)]+\)/g, "{}");

    js = js.replace(/printf\s*\(\s*"([^"]*)"(?:\s*,\s*([^;]+))?\s*\);/g, function(_, fmt, argsStr) {
      if (!argsStr || !argsStr.trim()) {
        return `__poly_out(${JSON.stringify(fmt.replace(/\\n/g, "\n"))});`;
      }
      const args = splitTopLevel(argsStr, ",");
      let parts = fmt.split(/%[0-9]*\.?[0-9]*[dsfculxX%]/);
      let out = "__poly_out(";
      for (let i = 0; i < parts.length; i++) {
        if (parts[i]) {
          out += JSON.stringify(parts[i].replace(/\\n/g, "\n"));
          if (i < args.length) out += " + ";
        }
        if (i < args.length) {
          out += `(${args[i].trim()})`;
          if (i < parts.length - 1 && parts[i + 1]) out += " + ";
        }
      }
      out += ");";
      return out;
    });

    if (isCpp) {
      js = js.replace(/cout\s*<<\s*([^;]+);/g, function(_, streamStr) {
        const parts = splitTopLevel(streamStr, "<<");
        let out = "__poly_out(";
        for (let i = 0; i < parts.length; i++) {
          let p = parts[i].trim();
          if (p === "endl") {
            out += "\"\\n\"";
          } else {
            out += `(${p})`;
          }
          if (i < parts.length - 1) out += " + ";
        }
        out += ");";
        return out;
      });

      js = js.replace(/\[[^\]]*\]\s*\(([^)]*)\)\s*(?:->\s*[^{]+)?\s*\{([^}]+)\}/g, function(_, params, body) {
        const cleanParams = params.split(",").map(p => {
          const parts = p.trim().split(/\s+/);
          return parts[parts.length - 1];
        }).join(", ");
        return `((${cleanParams}) => { ${body} })`;
      });

      js = js.replace(/sort\s*\(\s*([A-Za-z_]\w*)\.begin\(\)\s*,\s*\1\.end\(\)(?:,\s*([\s\S]*?))?\s*\)\s*;/g, function(_, name, comp) {
        if (comp && comp.trim()) return `${name}.sort(${comp.trim()});`;
        return `${name}.sort((a, b) => a - b);`;
      });

      js = js.replace(/vector\s*<[^>]+>\s*([A-Za-z_]\w*)(?:\s*=\s*\{([^}]+)\})?;/g, function(_, name, init) {
        return `let ${name} = [${init || ""}];`;
      });
      js = js.replace(/\.push_back\s*\(/g, ".push(");
      js = js.replace(/\.size\s*\(\s*\)/g, ".length");
    }

    js = js.replace(/\b(?:int|void|float|double|char|long|bool|auto|size_t)\s+(?:[*&]\s*)?([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{/g, function(_, name, params) {
      const cleanParams = params.split(",").map(p => {
        p = p.trim();
        const parts = p.split(/\s+/);
        return parts[parts.length - 1].replace(/[*&\[\]]/g, "");
      }).filter(Boolean).join(", ");
      return `function ${name}(${cleanParams}) {`;
    });

    js = js.replace(/\b(?:int|float|double|char|long|bool|auto|size_t)\s+(?:[*&]\s*)?([A-Za-z_]\w*)\s*\[([^\]]*)\]\s*=\s*\{([^}]+)\};/g, "let $1 = [$3];");
    js = js.replace(/\b(?:int|float|double|char|long|bool|auto|size_t)\s+(?:[*&]\s*)?([A-Za-z_]\w*)\s*\[([^\]]+)\];/g, "let $1 = new Array($2).fill(0);");
    js = js.replace(/\b(?:int|float|double|char|long|bool|auto|size_t)\s+(?:[*&]\s*)?([A-Za-z_]\w*)/g, "let $1");
    js = js.replace(/->/g, ".");

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
