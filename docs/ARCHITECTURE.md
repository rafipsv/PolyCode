# PolyCode Architecture

## Overview
PolyCode is designed with clear architectural boundaries separating the high-level consumer API from the concrete language execution runtimes.

```
+-------------------------------------------------------+
|                    PolyCode Facade                    |
|        (Public API, Configuration, Lifecycle)         |
+-------------------------------------------------------+
                           |
+-------------------------------------------------------+
|                   ExecutionManager                    |
|   (Timeouts, Cancellation, Byte-limiting, Events)     |
+-------------------------------------------------------+
           |                                  |
+--------------------+              +-------------------+
|  LanguageRegistry  |              |  EngineRegistry   |
| (Metadata, Status) |              | (Active Adapters) |
+--------------------+              +-------------------+
                                              |
                   +------------------------------------+
                   |     PolyCodeEngine / Compiler      |
                   |      (Adapter Base Interface)      |
                   +------------------------------------+
                                     |
           +-------------------------+-------------------------+
           |                         |                         |
+---------------------+   +---------------------+   +---------------------+
| Web Worker / WASM   |   | QuickJS / Pyodide   |   | Clang / Native WASM |
|   Browser Bridge    |   |  Embedded Runtime   |   |    Toolchain WASM   |
+---------------------+   +---------------------+   +---------------------+
```

## Layer Responsibilities
1. **Public Facade (`PolyCode`)**: Exposes clean methods (`execute`, `executeStream`, `compile`, `getPlatformCapabilities`) without leaking engine internals.
2. **Execution Coordinator (`ExecutionManager`)**: Ensures safety guarantees such as timeout thresholds, cancellation tokens, and bounded output memory.
3. **Engine Registries**: Modular plug-and-play system allowing engines to register dynamically based on platform availability.
4. **Execution Adapters (`PolyCodeEngine`)**: Encapsulates specific language execution logic behind uniform async/stream contracts.
