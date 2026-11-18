# Changelog

## 0.1.0

### PolyCode Core SDK
- **Multi-Language Architecture**: Unified facade (`PolyCode`) with full registration, capabilities discovery, and execution management across 9 languages:
  - **JavaScript**: Sandboxed Web Worker execution with QuickJS/V8 evaluation.
  - **Python**: MicroPython / Pyodide Web Worker runner with streaming I/O.
  - **C & C++**: Clang/LLVM WebAssembly compiler and execution engine with libc++ support.
  - **Rust**: In-browser wasm32 compilation and streaming Web Worker execution.
  - **Go**: Official `GOOS=js GOARCH=wasm` execution engine and glue layer.
  - **Java**: JVM bytecode compilation (`0xCAFEBABE`), host `javac`/`java` acceleration, and browser Web Worker evaluation.
  - **Kotlin**: Kotlin/Wasm compiler integration, host `kotlinc` runner, and structured diagnostics.
  - **Dart**: Standalone Dart VM host execution and Web Worker sandbox evaluation.
- **Diagnostics Normalization**: Structured diagnostic parsers (`ClangDiagnosticParser`, `RustDiagnosticParser`, `GoDiagnosticParser`, `JavaDiagnosticParser`, `KotlinDiagnosticParser`, `DartDiagnosticParser`) mapping line, column, severity, and error message.
- **Resource Sandboxing**: CPU timeouts, cancellation tokens, memory caps, stdout/stderr byte limits, and zero external cloud backend dependencies.

### PolyCode Playground & Web UI
- **Three Workspace Layouts**:
  - *Competitive Programming*: Split view with problem statements and custom test case runner.
  - *Code Block*: Minimal embeddable snippet card with toggleable output drawer.
  - *IDE*: Multi-file virtual workspace, file explorer tree, editor tabs, and bottom problems panel.
- **Theme & Preferences**: Centralized `ThemeExtension` tokens (`PolyCodeThemeTokens`), dark/light/high-contrast (WCAG AAA a11y) presets, and persistent storage.
- **Syntax Highlighting**: Real-time syntax highlighter controller (`SyntaxHighlighterEditingController`) optimized strictly under 100 lines.
- **Accessibility & Offline**: Full `Semantics` coverage, live screen reader announcements, offline service worker caching, and PWA manifest.
- **Deployment**: Automated GitHub Pages CI/CD workflow and reproducible release build scripts.
