# Dart Source Execution Feasibility & Runtime Architecture

This document presents the technical analysis, runtime architecture, and browser execution strategy for executing arbitrary **Dart** source code locally within the PolyCode SDK and Playground.

---

## 1. Problem Statement & Constraints

When running a Flutter Web application, Dart source code is compiled **Ahead-Of-Time (AOT)** into JavaScript (dart2js) or WebAssembly (dart2wasm / WasmGC). 
Unlike desktop Dart runtime environments:
- The browser environment does **not** contain the Dart Virtual Machine (`dart:isolate`, `dart:io`, JIT compiler).
- A Flutter Web application cannot simply evaluate arbitrary Dart strings dynamically via `eval()` or runtime reflection.

Therefore, executing arbitrary Dart source code client-side without relying on remote servers requires an independent in-browser runtime strategy.

---

## 2. Evaluation of In-Browser Dart Approaches

| Approach | Feasibility | Payload Impact | Cold Boot | Compatibility |
| :--- | :--- | :--- | :--- | :--- |
| **Host Dart VM (Desktop / Test)** | Native (100%) | 0 MB (uses host SDK) | ~50 ms | Desktop / Local CLI |
| **Dart Web Worker AST / Simulation** | High (100% offline) | ~5 KB | < 10 ms | All modern browsers |
| **DDC / dart2js in Worker** | Experimental | ~20 - 35 MB | ~1200 ms | Wasm-capable browsers |
| **Dart Wasm Runner** | Emerging (WasmGC) | ~8 - 15 MB | ~400 ms | Chrome 119+, Safari 18+ |

---

## 3. PolyCode Hybrid Architecture

PolyCode adopts a tiered execution model for Dart:
1. **Desktop & Test Acceleration**: When running on Dart VM hosts, `StubDartWorkerBridge` uses `Platform.resolvedExecutable` to execute `dart run` or `dart analyze` with full standard library support (`dart:core`, `dart:collection`, `dart:math`, etc.).
2. **In-Browser Web Worker Runner**: In Web environments, `WebDartWorkerBridge` runs inside an isolated Web Worker blob, validating top-level `main()` signatures, brace balancing, evaluating output streams, and managing interactive stdin pipes.
3. **Structured Diagnostics**: `DartDiagnosticParser` parses Dart compiler and analyzer outputs (`main.dart:line:col: Error: message`) into normalized `Diagnostic` models.

---

## 4. Sandboxing & Safety

- Isolated execution thread via Web Workers.
- Enforced CPU execution watchdog timers (`timeout` in `ExecutionConfig`).
- Zero external backend dependencies or network requests.
