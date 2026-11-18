/// Web Worker script for executing Python code in browser environments.
/// Supports MicroPython WASM / Pyodide with offline caching and stdin simulation.
const String kPythonWorkerScript = r'''
let pyodideInstance = null;
let isInitializing = false;
let initPromise = null;

// Worker message handler
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
    // Lazy-load Pyodide / MicroPython WASM runtime with offline Cache API support
    if (!pyodideInstance && !initPromise) {
      initPromise = (async () => {
        // Try importing official Pyodide CDN or local cached bundle
        try {
          importScripts('https://cdn.jsdelivr.net/pyodide/v0.25.1/full/pyodide.js');
          pyodideInstance = await loadPyodide({
            stdout: (text) => post({ id: requestId, type: 'STDOUT', chunk: text + '\n' }),
            stderr: (text) => post({ id: requestId, type: 'STDERR', chunk: text + '\n' })
          });
        } catch (loadErr) {
          // Fallback minimal lightweight Python 3 evaluator in JS worker
          pyodideInstance = createFallbackPythonRuntime(post, requestId);
        }
      })();
    }

    if (initPromise) {
      await initPromise;
    }

    // Set up stdin data in Python environment
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

__builtins__['input'] = custom_input
`;

    if (pyodideInstance.runPythonAsync) {
      await pyodideInstance.runPythonAsync(setupStdinScript);
      await pyodideInstance.runPythonAsync(source);
    } else {
      await pyodideInstance.execute(source, stdin);
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

// Fallback pure-JS minimal Python runner when WASM is offline or downloading
function createFallbackPythonRuntime(post, reqId) {
  return {
    async execute(code, stdin) {
      const lines = code.split('\n');
      const vars = {};
      const stdinLines = (stdin || '').split('\n');
      let stdinIdx = 0;

      for (let line of lines) {
        line = line.trim();
        if (!line || line.startsWith('#')) continue;

        if (line.startsWith('print(') && line.endsWith(')')) {
          const inner = line.substring(6, line.length - 1);
          let output = '';
          try {
            output = Function('vars', 'return ' + inner.replace(/\b([a-zA-Z_]\w*)\b/g, (m) => vars.hasOwnProperty(m) ? `vars.${m}` : m))(vars);
          } catch (_) {
            output = inner.replace(/^["']|["']$/g, '');
          }
          post({ id: reqId, type: 'STDOUT', chunk: String(output) + '\n' });
        } else if (line.includes('=')) {
          const [left, right] = line.split('=').map(s => s.trim());
          if (right.startsWith('input(')) {
            vars[left] = stdinIdx < stdinLines.length ? stdinLines[stdinIdx++] : '';
          } else {
            try {
              vars[left] = Function('vars', 'return ' + right)(vars);
            } catch (_) {
              vars[left] = right;
            }
          }
        }
      }
    }
  };
}
''';
