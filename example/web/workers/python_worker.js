// PolyCode Python Sandboxed Web Worker
let pyodideInstance = null;
let initPromise = null;

function transpilePython(pyCode) {
  let lines = pyCode.split("\n");
  let jsLines = [];
  let indentStack = [0];

  function getIndent(line) {
    let count = 0;
    while (count < line.length && (line[count] === " " || line[count] === "\t")) {
      count++;
    }
    return count;
  }

  for (let rawLine of lines) {
    let lineWithoutComment = rawLine.replace(/#.*$/, "");
    if (!lineWithoutComment.trim()) continue;

    let indent = getIndent(lineWithoutComment);
    let trimmed = lineWithoutComment.trim();

    while (indent < indentStack[indentStack.length - 1]) {
      indentStack.pop();
      jsLines.push(" ".repeat(indentStack[indentStack.length - 1]) + "}");
    }

    let isBlock = trimmed.endsWith(":");
    let content = isBlock ? trimmed.slice(0, -1).trim() : trimmed;
    let js = "";

    if (content.startsWith("def ")) {
      let match = content.match(/^def\s+([A-Za-z_]\w*)\s*\((.*?)\)$/);
      if (match) {
        let name = match[1];
        let params = match[2].split(",").map(p => p.trim()).filter(Boolean);
        if (params[0] === "self") params.shift();
        js = "function " + name + "(" + params.join(", ") + ") {";
      }
    } else if (content.startsWith("class ")) {
      let match = content.match(/^class\s+([A-Za-z_]\w*)/);
      if (match) {
        js = "class " + match[1] + " {";
      }
    } else if (content.startsWith("if ")) {
      js = "if (" + content.slice(3) + ") {";
    } else if (content.startsWith("elif ")) {
      js = "else if (" + content.slice(5) + ") {";
    } else if (content === "else") {
      js = "else {";
    } else if (content.startsWith("while ")) {
      js = "while (" + content.slice(6) + ") {";
    } else if (content.startsWith("for ")) {
      let forMatch = content.match(/^for\s+([A-Za-z_]\w*)\s+in\s+range\((.*?)\)$/);
      if (forMatch) {
        let varName = forMatch[1];
        let args = forMatch[2].split(",").map(a => a.trim());
        if (args.length === 1) {
          js = `for (let ${varName} = 0; ${varName} < (${args[0]}); ${varName}++) {`;
        } else if (args.length === 2) {
          js = `for (let ${varName} = (${args[0]}); ${varName} < (${args[1]}); ${varName}++) {`;
        } else {
          js = `for (let ${varName} = (${args[0]}); ${varName} < (${args[1]}); ${varName} += (${args[2]})) {`;
        }
      } else {
        let inMatch = content.match(/^for\s+([A-Za-z_]\w*)\s+in\s+(.*?)$/);
        if (inMatch) {
          js = `for (let ${inMatch[1]} of (${inMatch[2]})) {`;
        }
      }
    } else if (content.startsWith("print(") && content.endsWith(")")) {
      let inner = content.slice(6, -1);
      js = `__poly_out(String(${inner}) + "\\n");`;
    } else {
      js = content + ";";
    }

    if (isBlock) {
      indentStack.push(indent + 4);
    }

    js = js.replace(/\bTrue\b/g, "true")
           .replace(/\bFalse\b/g, "false")
           .replace(/\bNone\b/g, "null")
           .replace(/\bself\./g, "this.")
           .replace(/\.append\(/g, ".push(");

    jsLines.push(" ".repeat(indent) + js);
  }

  while (indentStack.length > 1) {
    indentStack.pop();
    jsLines.push(" ".repeat(indentStack[indentStack.length - 1]) + "}");
  }

  return jsLines.join("\n");
}

self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'py_0';
  const source = data.source || '';
  const stdin = data.stdin || '';

  function post(msg) {
    self.postMessage(JSON.stringify(msg));
  }

  const startTime = performance.now();

  try {
    let executed = false;

    // Try Pyodide if already loaded or reachable
    if (!pyodideInstance && !initPromise) {
      initPromise = (async () => {
        try {
          importScripts('https://cdn.jsdelivr.net/pyodide/v0.25.1/full/pyodide.js');
          pyodideInstance = await loadPyodide({
            stdout: (text) => post({ id: requestId, type: 'STDOUT', chunk: text + '\n' }),
            stderr: (text) => post({ id: requestId, type: 'STDERR', chunk: text + '\n' })
          });
        } catch (_) {}
      })();
    }

    if (initPromise) {
      try {
        await Promise.race([
          initPromise,
          new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 1500))
        ]);
      } catch (_) {}
    }

    if (pyodideInstance) {
      try {
        const setupStdinScript = `
import sys
_stdin_data = ${JSON.stringify(stdin)}
_stdin_lines = _stdin_data.split('\\n') if _stdin_data else []
_stdin_idx = 0

def custom_input(prompt=''):
    global _stdin_idx
    if prompt:
        sys.stdout.write(prompt)
    if _stdin_idx < len(_stdin_lines):
        val = _stdin_lines[_stdin_idx]
        _stdin_idx += 1
        return val
    return ''

__builtins__.input = custom_input
`;
        await pyodideInstance.runPythonAsync(setupStdinScript);
        await pyodideInstance.runPythonAsync(source);
        executed = true;
      } catch (runErr) {
        // If Pyodide encountered runtime error, report it
        post({ id: requestId, type: 'STDERR', chunk: String(runErr) + '\n' });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: String(runErr)
        });
        return;
      }
    }

    if (!executed) {
      // Local fast Python-to-JS algorithmic execution
      if (stdin && stdin.trim()) {
        post({ id: requestId, type: 'STDOUT', chunk: `[stdin: ${stdin.trim()}]\n` });
      }

      const jsCode = transpilePython(source);
      const runner = new Function('__poly_out', jsCode);
      runner(function(chunk) {
        post({ id: requestId, type: 'STDOUT', chunk: String(chunk) });
      });
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
    const errText = err && (err.message || err.toString()) ? String(err.message || err.toString()) : 'Python execution error';
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
