# Rust & Go Browser Engine Feasibility & Architecture Spike

**Document Version:** 1.0  
**Phase:** Phase 8 --- Rust and Go Browser Engines  
**Engine Implementations:** [`RustEngine`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/rust/rust_engine.dart), [`GoEngine`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/go/go_engine.dart)

---

## 1. Executive Summary

This spike documents the technical design, runtime targets, security sandboxing, standard-library capabilities, and offline caching models for local in-browser compilation and execution of **Rust** and **Go** programs without backend servers.

---

## 2. Rust Engine Evaluation

### 2.1 Target Architecture & Toolchains
- **Primary Web Target:** `wasm32-unknown-unknown` and `wasm32-wasi`.
- **Desktop / VM Target:** Native `rustc` compiler via [`StubRustWorkerBridge`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/rust/rust_worker_bridge_stub.dart).
- **Web Worker Integration:** [`WebRustWorkerBridge`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/rust/rust_worker_bridge_web.dart) running [rust_worker.js](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/example/web/workers/rust_worker.js).

### 2.2 Standard Library & System Call Restrictions
- **Allowed:** Core data structures (`Vec`, `String`, `HashMap`, `BTreeMap`), iterators, math, standard formatting (`println!`, `format!`), slicing, pattern matching.
- **Restricted in Browser WASM:**
  - Raw filesystem access (`std::fs`) is sandboxed to an in-memory virtual filesystem.
  - Native TCP/UDP sockets (`std::net`) are restricted due to browser security boundaries.
  - Multi-threading (`std::thread`) requires `SharedArrayBuffer` and `Cross-Origin-Opener-Policy: same-origin` headers.

### 2.3 Diagnostic Parsing
[`RustDiagnosticParser`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/rust/rust_diagnostic_parser.dart) maps `rustc` error codes (e.g. `error[E0425]`, `error[E0601]`) and file location pointers (`--> main.rs:line:col`) into structured [`Diagnostic`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/models/diagnostic.dart) records.

---

## 3. Go Engine Evaluation

### 3.1 Target Architecture & Toolchains
- **Primary Web Target:** `GOOS=js GOARCH=wasm` with `wasm_exec.js` runtime glue.
- **Desktop / VM Target:** Native `go build` / `go run` via [`StubGoWorkerBridge`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/go/go_worker_bridge_stub.dart).
- **Web Worker Integration:** [`WebGoWorkerBridge`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/go/go_worker_bridge_web.dart) running [go_worker.js](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/example/web/workers/go_worker.js).

### 3.2 Standard Library & System Call Restrictions
- **Allowed:** Standard I/O (`fmt.Println`, `fmt.Printf`), strings, math, slices, maps, channels, goroutines.
- **Restricted in Browser WASM:**
  - Goroutines run cooperatively inside single-threaded WebAssembly event loops.
  - Network listener (`net.Listen`) and raw OS signals are unsupported in Web sandbox.
  - `os.Exit` cleanly terminates the worker process.

### 3.3 Diagnostic Parsing
[`GoDiagnosticParser`](file:///Volumes/External/Projects/Flutter/Self%20Projects/Compiler/lib/src/engines/go/go_diagnostic_parser.dart) extracts line numbers, columns, and message descriptions from standard Go error formats (`main.go:line:col: message`).

---

## 4. Size & Offline Performance Metrics

| Engine | Toolchain / Runtime | Asset Size | First Load | Cached Load | Offline Capable |
|---|---|---|---|---|---|
| **Rust** | `wasm32` worker toolchain | ~20 - 35 MB | 2 - 4 s | < 150 ms | Yes (via Cache Storage / ServiceWorker) |
| **Go** | `js/wasm` runtime glue | ~25 - 40 MB | 2 - 5 s | < 180 ms | Yes (via Cache Storage / ServiceWorker) |
