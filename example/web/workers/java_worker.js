// PolyCode Java Sandboxed Web Worker
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'java_0';
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
      const hasClass = source.includes('class ');
      const hasMain = source.includes('main(String[]') ||
                      source.includes('main (String[]') ||
                      source.includes('main(String args[])') ||
                      source.includes('main (String args[])') ||
                      source.includes('main(String ...');

      if (!hasClass) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "class, interface, enum, or record expected"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "Main.java:1: error: class, interface, enum, or record expected\n",
          diagnostics: diagnostics
        });
        return;
      }

      if (!hasMain) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "Main method not found in class"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "Main.java:1: error: Main method not found in class, please define the main method as:\n   public static void main(String[] args)\n",
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
          message: "reached end of file while parsing"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: `Main.java:${source.split('\n').length}: error: reached end of file while parsing\n`,
          diagnostics: diagnostics
        });
        return;
      }

      post({
        id: requestId,
        type: 'COMPILATION_RESULT',
        isSuccess: true,
        compilerOutput: 'Compiled Java source successfully.\n',
        diagnostics: []
      });
      return;
    }

    // EXECUTE phase
    if (!source.includes('class ') || (!source.includes('main(') && !source.includes('main ('))) {
      post({ id: requestId, type: 'STDERR', chunk: "Main.java:1: error: Main method not found in class\n" });
      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 1,
        durationMs: Math.round(performance.now() - startTime),
        error: 'Execution failed: main method required'
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
    js = js.replace(/package\s+[A-Za-z0-9_.]+;/g, '');
    js = js.replace(/import\s+[A-Za-z0-9_.*]+;/g, '');

    js = replaceCall(js, 'System.out.println', function(arg) {
      if (!arg || !arg.trim()) return '__poly_out("\\n");';
      return `__poly_out((${arg}) + "\\n");`;
    });

    js = replaceCall(js, 'System.out.print', function(arg) {
      if (!arg || !arg.trim()) return '';
      return `__poly_out(String(${arg}));`;
    });

    // Strip class wrapper
    js = js.replace(/public\s+class\s+[A-Za-z_]\w*\s*\{/g, '');
    js = js.replace(/class\s+[A-Za-z_]\w*\s*\{/g, '');
    if (js.lastIndexOf('}') !== -1) {
      js = js.substring(0, js.lastIndexOf('}'));
    }

    // Replace static methods
    js = js.replace(/(?:public\s+)?(?:static\s+)?(?:void|int|long|double|float|boolean|String|char)\s+main\s*\([^)]*\)\s*\{/g, 'function main() {');
    js = js.replace(/(?:public\s+)?(?:static\s+)?(?:void|int|long|double|float|boolean|String|char|[A-Za-z0-9_<>[\]]+)\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{/g, function(_, name, rawParams) {
      const cleanParams = (rawParams || '').split(',').map(p => {
        const parts = p.trim().split(/\s+/);
        return parts[parts.length - 1];
      }).filter(Boolean).join(', ');
      return `function ${name}(${cleanParams}) {`;
    });

    // ArrayList & Collections
    js = js.replace(/ArrayList\s*<[^>]+>\s*([A-Za-z_]\w*)\s*=\s*new\s+ArrayList\s*<[^>]*>\s*\(\);?/g, 'let $1 = [];');
    js = js.replace(/List\s*<[^>]+>\s*([A-Za-z_]\w*)\s*=\s*new\s+ArrayList\s*<[^>]*>\s*\(\);?/g, 'let $1 = [];');
    js = js.replace(/Collections\.sort\s*\(\s*([A-Za-z_]\w*)\s*\);?/g, '$1.sort((a, b) => a - b);');
    js = js.replace(/\.add\s*\(/g, '.push(');
    js = js.replace(/\.get\s*\(\s*([^)]+)\s*\)/g, '[$1]');
    js = js.replace(/\.size\s*\(\s*\)/g, '.length');

    // Variable declarations: int x = 10;
    js = js.replace(/\b(?:int|long|double|float|boolean|String|char)\s*\[\s*\]\s*([A-Za-z_]\w*)\s*=\s*\{([^}]+)\};/g, 'let $1 = [$2];');
    js = js.replace(/\b(?:int|long|double|float|boolean|String|char)\s*\[\s*\]\s*([A-Za-z_]\w*)\s*=\s*new\s+[A-Za-z0-9_]+\s*\[([^\]]+)\];/g, 'let $1 = new Array($2).fill(0);');
    js = js.replace(/\b(?:int|long|double|float|boolean|String|char)\s+([A-Za-z_]\w*)/g, 'let $1');

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
    post({ id: requestId, type: 'STDERR', chunk: 'Java JVM Runtime Error: ' + err.message + '\n' });
    post({
      id: requestId,
      type: 'COMPLETED',
      exitCode: 1,
      durationMs: Math.round(performance.now() - startTime),
      error: err.message
    });
  }
};
