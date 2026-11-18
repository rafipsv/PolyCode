/// The sandboxed Web Worker script executed in browser environments.
const String kJavaScriptWorkerScript = r'''
self.onmessage = async function(event) {
  let data = event.data || {};
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {}
  }

  const requestId = data.id || 'req_0';
  const source = data.source || '';
  const stdin = data.stdin || '';

  function post(msg) {
    self.postMessage(JSON.stringify(msg));
  }

  const customConsole = {
    log: function(...args) {
      const text = args.map(a => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' ') + '\n';
      post({ id: requestId, type: 'STDOUT', chunk: text });
    },
    info: function(...args) {
      customConsole.log(...args);
    },
    warn: function(...args) {
      const text = args.map(a => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' ') + '\n';
      post({ id: requestId, type: 'STDERR', chunk: text });
    },
    error: function(...args) {
      const text = args.map(a => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' ') + '\n';
      post({ id: requestId, type: 'STDERR', chunk: text });
    }
  };

  let stdinLines = stdin ? stdin.split('\n') : [];
  let stdinCursor = 0;
  function readline() {
    if (stdinCursor < stdinLines.length) {
      return stdinLines[stdinCursor++];
    }
    return null;
  }

  const startTime = performance.now();
  try {
    const runner = new Function(
      'console',
      'print',
      'readline',
      'input',
      '"use strict";\n' + source
    );

    const result = runner(customConsole, customConsole.log, readline, readline);
    if (result instanceof Promise) {
      await result;
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
    const errText = err && (err.stack || err.message) ? String(err.stack || err.message) : String(err);
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
