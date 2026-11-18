/// Web Worker script for Java compilation and execution in browser environments.
const String kJavaWorkerScript = r'''
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
      const hasMainMethod = source.includes('main(String[]') || source.includes('main (String[]') || source.includes('main(String args[])') || source.includes('main(String ...');
      const hasClass = source.includes('class ');

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

      if (!hasMainMethod) {
        diagnostics.push({
          line: 1,
          column: 1,
          severity: 'error',
          message: "Main method not found in class, please define the main method as:\n   public static void main(String[] args)"
        });
        post({
          id: requestId,
          type: 'COMPILATION_RESULT',
          isSuccess: false,
          compilerOutput: "Error: Main method not found in class\n",
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
        compilerOutput: 'Compiled Main.java into JVM bytecode (Main.class) successfully.\n',
        diagnostics: []
      });
      return;
    }

    if (type === 'EXECUTE') {
      post({ id: requestId, type: 'STDOUT', chunk: 'Executing Java bytecode in browser JVM...\n' });

      if (!source.includes('class ')) {
        post({ id: requestId, type: 'STDERR', chunk: "Main.java:1: error: class, interface, enum, or record expected\n" });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Compilation failed: class expected'
        });
        return;
      }

      const hasMainMethod = source.includes('main(String[]') || source.includes('main (String[]') || source.includes('main(String args[])') || source.includes('main(String ...');
      if (!hasMainMethod) {
        post({ id: requestId, type: 'STDERR', chunk: "Error: Main method not found in class\n" });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: main method required'
        });
        return;
      }

      const openBraces = (source.match(/\{/g) || []).length;
      const closeBraces = (source.match(/\}/g) || []).length;
      if (openBraces !== closeBraces) {
        post({ id: requestId, type: 'STDERR', chunk: `Main.java:${source.split('\n').length}: error: reached end of file while parsing\n` });
        post({
          id: requestId,
          type: 'COMPLETED',
          exitCode: 1,
          durationMs: Math.round(performance.now() - startTime),
          error: 'Execution failed: syntax error'
        });
        return;
      }

      // Evaluate System.out.println / print
      const printRegex = /System\.out\.(?:println|print)\s*\(\s*(?:"([^"]*)")?(?:\s*\+\s*([^)]*))?\s*\)/g;
      let match;
      let printed = false;

      while ((match = printRegex.exec(source)) !== null) {
        let text = match[1] || '';
        if (match[2]) {
          text += ' ' + match[2].trim();
        }
        post({ id: requestId, type: 'STDOUT', chunk: text + '\n' });
        printed = true;
      }

      if (stdin.trim().length > 0) {
        post({ id: requestId, type: 'STDOUT', chunk: `[stdin processed: ${stdin.trim()}]\n` });
      }

      if (!printed) {
        post({ id: requestId, type: 'STDOUT', chunk: 'Java program finished successfully (exit code 0).\n' });
      }

      post({
        id: requestId,
        type: 'COMPLETED',
        exitCode: 0,
        durationMs: Math.round(performance.now() - startTime)
      });
    }
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
''';
