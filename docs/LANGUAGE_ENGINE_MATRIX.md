# Language Engine Matrix

This matrix tracks the candidate runtimes, technical directions, and feasibility status across all nine target languages.

| Language | Candidate Runtime | License | Web Target | Estimated Size | Status | Notes |
|---|---|---|---|---|---|---|
| **JavaScript** | QuickJS (WASM) / Web Worker | MIT | Yes | ~500 KB - 1 MB | Planned (Phase 2) | Ultra-lightweight, sandboxed in Web Worker. |
| **Python** | MicroPython / Pyodide WASM | MIT / PSF | Yes | 1 MB - 15 MB | Planned (Phase 3) | MicroPython for speed/lightweight; Pyodide for full standard library. |
| **C** | Clang / LLVM WASM Toolchain | Apache 2.0 with LLVM Exception | Yes | ~15 - 25 MB | Planned (Phase 4) | Direct WASM compilation and execution in worker. |
| **C++** | Clang / LLVM WASM Toolchain | Apache 2.0 with LLVM Exception | Yes | ~20 - 30 MB | Planned (Phase 4) | Includes libc++ runtime. |
| **Rust** | Rust wasm32-unknown-unknown | MIT / Apache 2.0 | Experimental | ~25 - 40 MB | Planned (Phase 8) | In-browser toolchain requires investigation. |
| **Go** | Go compiler js/wasm target | BSD-3-Clause | Experimental | ~30 - 45 MB | Planned (Phase 8) | Go runtime glue layer needed. |
| **Java** | JVM WASM / Compiler toolchain | GPLv2 with Classpath / Apache | High Risk | ~40+ MB | Planned (Phase 9) | Feasibility spike to verify browser bytecode execution. |
| **Kotlin** | Kotlin/Wasm or Kotlin/JS | Apache 2.0 | High Risk | ~40+ MB | Planned (Phase 9) | Transpilation vs bytecode evaluation comparison. |
| **Dart** | Standalone Dart evaluator | BSD-3-Clause | Investigation | Variable | Planned (Phase 10) | Requires separate evaluator from host Flutter runtime. |
