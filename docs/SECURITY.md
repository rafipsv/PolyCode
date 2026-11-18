# Security Model and Principles

PolyCode executes arbitrary user-supplied code. The following principles govern all runtime integrations:

## 1. Web Execution Security
- **Worker Isolation**: Code runtimes execute inside dedicated Web Workers, preventing execution loops from blocking the Flutter UI thread.
- **No Direct DOM Access**: Web Workers do not have access to the main window DOM or parent storage credentials.
- **Output Bounding**: Stdout and Stderr are streamed into bounded buffers (`maxOutputBytes`), preventing memory exhaustion crashes.
- **Timeout Termination**: Workers that exceed configured execution time thresholds are killed and disposed.

## 2. No-Backend Privacy
- All code compilation and execution occurs locally on the client's browser or device.
- No source code or input data is transmitted to external servers, APIs, or third-party cloud compilers.

## 3. Honest Security Limits
- Web Workers and WebAssembly provide strong process isolation within browser boundaries, but are subject to browser sandbox capabilities.
- PolyCode makes no claims of a military-grade or OS kernel-level sandbox against speculative execution or native side-channel vectors.
