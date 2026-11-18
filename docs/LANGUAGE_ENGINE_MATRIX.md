# Language Engine Matrix

This matrix tracks the candidate runtimes, technical directions, and feasibility status across all nine target languages.

| Language | Candidate Runtime | License | Web Target | Estimated Size | Status | Notes |
|---|---|---|---|---|---|---|
| **JavaScript** | QuickJS (WASM) / Web Worker | MIT | Yes | ~500 KB - 1 MB | Available (Phase 2) | Ultra-lightweight, sandboxed in Web Worker. |
| **Python** | MicroPython / Pyodide WASM | MIT / PSF | Yes | 1 MB - 15 MB | Available (Phase 3) | MicroPython for speed/lightweight; Pyodide for full standard library. |
| **C** | Clang / LLVM WASM Toolchain | Apache 2.0 with LLVM Exception | Yes | ~15 - 25 MB | Available (Phase 4) | Direct WASM compilation and execution in worker. |
| **C++** | Clang / LLVM WASM Toolchain | Apache 2.0 with LLVM Exception | Yes | ~20 - 30 MB | Available (Phase 4) | Includes libc++ runtime. |
| **Rust** | Rust wasm32-unknown-unknown | MIT / Apache 2.0 | Yes | ~20 - 35 MB | Available (Phase 8) | In-browser wasm32 compilation + streaming Web Worker execution. |
| **Go** | Go compiler js/wasm target | BSD-3-Clause | Yes | ~25 - 40 MB | Available (Phase 8) | Official Go wasm target + wasm_exec glue layer. |
| **Java** | JVM WASM / Compiler toolchain | GPLv2 with Classpath / Apache | Yes | ~15 - 40 MB | Available (Phase 9) | Host javac/java + browser Web Worker JVM bytecode execution. |
| **Kotlin** | Kotlin/Wasm or Kotlin/JVM | Apache 2.0 | Yes | ~5 - 35 MB | Available (Phase 9) | Host kotlinc/java + Kotlin/Wasm browser Web Worker execution. |
| **Dart** | Standalone Dart evaluator | BSD-3-Clause | Investigation | Variable | Planned (Phase 10) | Requires separate evaluator from host Flutter runtime. |
