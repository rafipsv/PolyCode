# PolyCode

A modular, local-first code execution and compilation SDK for Dart and Flutter with no backend server dependencies.

## Features
- **Local-first Execution**: Runs code directly on-device or in-browser via WebAssembly and Web Workers.
- **Unified Facade**: Single consistent Dart API (`PolyCode`) across all supported languages.
- **Streaming Lifecycle**: Stream real-time stdout, stderr, compile diagnostics, and status events.
- **Extensible Adapters**: Pluggable engine architecture for community or custom runtimes.

## Getting Started

```dart
import 'package:polycode/polycode.dart';

void main() async {
  final polycode = PolyCode();

  // Inspect platform capabilities
  final caps = polycode.getPlatformCapabilities();
  print('Platform: ${caps.platform.name}');

  // Dispose when finished
  await polycode.dispose();
}
```
