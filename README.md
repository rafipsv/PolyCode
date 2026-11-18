# PolyCode

[![pub package](https://img.shields.io/badge/pub.dev-polycode-blue.svg)](https://pub.dev/packages/polycode)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter Web](https://img.shields.io/badge/platform-Flutter%20Web%20%7C%20Desktop-teal.svg)](https://flutter.dev)

A modular, local-first code execution and compilation SDK for Dart and Flutter with **zero remote backend dependencies**. 

PolyCode empowers developers to compile and run code in **9 programming languages** directly inside the client browser or desktop environment using WebAssembly, Web Workers, and host toolchain acceleration.

---

## Language Support Matrix

| Language | Engine / Target | Compilation Mode | Web Worker | Diagnostics |
| :--- | :--- | :--- | :--- | :--- |
| **JavaScript** | QuickJS / V8 Sandbox | Interpreted | Yes | Runtime stack traces |
| **Python** | MicroPython / Pyodide | Interpreted | Yes | Python tracebacks |
| **C** | Clang WASM / Native | Compiled | Yes | Structured Clang errors |
| **C++** | Clang++ WASM (libc++) | Compiled | Yes | Structured Clang errors |
| **Rust** | `rustc` wasm32 / Native | Compiled | Yes | Structured `rustc` errors |
| **Go** | Go `js/wasm` / Native | Compiled | Yes | Structured Go errors |
| **Java** | JVM Bytecode / Host `javac` | Compiled | Yes | Structured `javac` errors |
| **Kotlin** | Kotlin/Wasm / Host `kotlinc` | Compiled | Yes | Structured `kotlinc` errors |
| **Dart** | Dart VM / Web Worker | Interpreted & Compiled | Yes | Structured Dart analyzer |

---

## Key Features

- **100% Local-First & Private**: Code execution occurs entirely on the user's machine. No source code or telemetry is ever transmitted to external servers.
- **Unified Facade**: Single consistent API across all 9 languages via `PolyCode`.
- **Real-Time Streaming**: Stream real-time `stdout`, `stderr`, lifecycle events, and compilation progress.
- **Normalized Diagnostics**: Standardized `Diagnostic` model extracting file, line, column, severity, and error message across all compilers.
- **Resilient Sandboxing**: Watchdog execution timeouts, cooperative cancellation tokens, memory constraints, and byte limits.
- **Playground Shell with 3 Workspace Layouts**:
  1. *Competitive Programming*: Split view with problem statements and custom test case runner.
  2. *Code Block*: Minimal embeddable snippet card with toggleable terminal drawer.
  3. *IDE*: Multi-file virtual workspace, file explorer tree, editor tabs, and bottom problems panel.
- **WCAG AAA Accessibility**: Fully semantic controls, screen reader announcements, and high-contrast color tokens.
- **Offline PWA Ready**: Service worker caching and web manifest for offline code compilation and execution.

---

## Installation

Add PolyCode to your `pubspec.yaml`:

```yaml
dependencies:
  polycode: ^0.1.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize and Inspect Capabilities

```dart
import 'package:polycode/polycode.dart';

void main() async {
  final polycode = PolyCode();

  // Inspect platform capabilities
  final caps = polycode.getPlatformCapabilities();
  print('Available languages: ${caps.availableLanguages.map((l) => l.displayName).join(", ")}');

  // Dispose when no longer needed
  await polycode.dispose();
}
```

### 2. Execute Code

```dart
final result = await polycode.execute(
  const ExecutionRequest(
    language: PolyLanguage.rust,
    source: '''
fn main() {
    println!("Hello from PolyCode Rust!");
}
''',
  ),
);

if (result.isSuccess) {
  print('Output:\n${result.stdout}');
} else {
  print('Error:\n${result.stderr}');
}
```

### 3. Real-Time Event Streaming & Interactive Stdin

```dart
final stream = polycode.executeStream(
  const ExecutionRequest(
    language: PolyLanguage.python,
    source: '''
name = input("Enter your name: ")
print(f"Welcome, {name}!")
''',
    stdin: 'Alice\n',
  ),
);

await for (final event in stream) {
  if (event is StdoutExecutionEvent) {
    print('[STDOUT] ${event.chunk}');
  } else if (event is StderrExecutionEvent) {
    print('[STDERR] ${event.chunk}');
  } else if (event is CompletedExecutionEvent) {
    print('[DONE] Exit Code: ${event.result.exitCode}');
  }
}
```

---

## Architecture Overview

```
                        +---------------------------+
                        |   PolyCode Unified SDK    |
                        +-------------+-------------+
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
+--------v---------+         +--------v---------+         +--------v---------+
| JavaScriptEngine |         |   PythonEngine   |         |    RustEngine    |
+--------+---------+         +--------+---------+         +--------+---------+
         |                            |                            |
+--------v---------+         +--------v---------+         +--------v---------+
| ClangEngine(C++) |         |     GoEngine     |         |    JavaEngine    |
+--------+---------+         +--------+---------+         +--------+---------+
         |                            |                            |
+--------v---------+         +--------v---------+         +--------v---------+
|   KotlinEngine   |         |    DartEngine    |         |  Custom Engines  |
+------------------+         +------------------+         +------------------+
```

---

## Playground Web Demo

To run the interactive web playground locally:

```bash
cd example
flutter run -d chrome
```

Or build the production release bundle:

```bash
./scripts/build_web.sh
```

---

## License

PolyCode is open-source software licensed under the [MIT License](LICENSE).  
For third-party compiler and runtime licenses, see [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
