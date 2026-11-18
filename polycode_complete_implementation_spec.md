# PolyCode --- Complete Product & Engineering Specification

**Document version:** 1.0\
**Project type:** Open-source Dart/Flutter local code execution SDK +
Flutter Web compiler playground\
**Primary deliverables:** Pub.dev package first, then Flutter Web
application\
**Initial application platforms:** Web (GitHub Pages)\
**Mobile app:** Explicitly out of scope for this phase; Android app will
be planned after the Web product is stable\
**State management:** `flutter_bloc` / BLoC\
**Execution model:** Hybrid, local-only, no backend and no external
execution API

------------------------------------------------------------------------

## 0. Instructions to the AI Coding Agent

Act as a senior Dart, Flutter, WebAssembly, compiler-runtime, and
open-source package engineer.

Build this project in the phases defined below. Do not skip phases, do
not claim features are complete unless they work, and do not replace
real execution with hard-coded or fake output.

### Mandatory working rules

1.  **Inspect before coding.** Inspect the repository, SDK versions,
    available tools, and existing code before making changes.
2.  **Create a plan and phase checklist.** Keep
    `docs/IMPLEMENTATION_STATUS.md` updated after each phase.
3.  **Build incrementally.** Complete one phase, run its tests, fix
    failures, and only then start the next phase.
4.  **No fake compiler.** A mock engine may be used in unit tests only.
    Never register a mock as a real supported language engine.
5.  **No backend.** Do not introduce a server, cloud compiler, external
    execution API, account system, or server-side dependency.
6.  **Local execution only.** Source code must execute on the user's
    device or in the user's browser using an embedded/native/WASM
    runtime.
7.  **Honest platform support.** A language is `available` only after a
    real compile/execute integration test passes on that platform.
    Otherwise mark it `experimental`, `requiresRuntime`, `planned`, or
    `unsupported`.
8.  **No unsafe execution claims.** Dart isolates are not a security
    sandbox for arbitrary native code. Do not claim complete sandboxing
    unless the actual runtime and OS restrictions enforce it.
9.  **Do not bundle huge runtimes blindly.** Measure package, download,
    APK, and web asset sizes. Document runtime licenses and
    redistribution terms.
10. **Keep public APIs stable.** Use semantic versioning. Avoid
    publishing experimental APIs as stable.
11. **Do not add dependencies without a reason.** Check current package
    maintenance, license, platform support, compatibility, and size
    before adding any dependency.
12. **Do not build the Android app now.** The current scope is the
    Pub.dev package and the Flutter Web playground. Keep the package
    architecture extensible for Android later.
13. **Do not assume all nine languages can run on both Web and
    Android.** Prove feasibility engine by engine.
14. At the end of every phase, report: files changed, commands run,
    tests passed/failed, build results, known limitations, and the next
    phase.

### Initial language goals

-   C
-   C++
-   Python
-   JavaScript
-   Java
-   Kotlin
-   Dart
-   Rust
-   Go

These are product targets, not a promise that all nine will be supported
in the first release.

------------------------------------------------------------------------

# PART A --- PRODUCT VISION AND SCOPE

## 1. Product definition

PolyCode consists of two related deliverables:

### A. `polycode` --- public Dart/Flutter package

A reusable SDK published on Pub.dev. It provides a consistent Dart API
to discover available language engines, compile source code where
compilation is supported, execute code locally, pass standard input, and
receive normalized output/errors.

### B. PolyCode Playground --- Flutter Web application

A polished browser-based local compiler playground built using the
public `polycode` package. It will be hosted as a static site on GitHub
Pages.

The Web application must not contain a backend. It must use
browser-compatible runtimes (primarily WebAssembly and JavaScript
engines) and browser storage where needed.

### Explicitly out of scope for the current delivery

-   Android application and Play Store release.
-   User accounts, cloud sync, online judge, server execution, remote
    API.
-   Collaborative editing and multi-user sessions.
-   AI code completion.
-   Guaranteed support for every language on every browser/device.
-   Downloading and executing arbitrary native binaries in the browser.

## 2. Product principles

-   Local-first and offline-capable after required assets have been
    cached.
-   No backend or external execution service.
-   One consistent public Dart API.
-   Language engines are modular and replaceable.
-   UI is independent from compiler implementation.
-   Platform capabilities are discoverable at runtime.
-   Clear compile errors, runtime errors, stdin, stdout, stderr, exit
    status, and execution duration.
-   Multiple editor layouts and themes.
-   Accessibility, responsive design, and keyboard-first workflows.
-   Transparent limitations and runtime download sizes.

## 3. Important technical reality

A Flutter Web app cannot run native desktop compiler executables. GitHub
Pages only hosts static files. Browser execution must use
browser-compatible engines such as WebAssembly modules, JavaScript/WASM
runtimes, and Web Workers.

The fact that Flutter Web itself is compiled to JavaScript or
WebAssembly does **not** provide a compiler for C, C++, Python, Java,
Kotlin, Dart, Rust, or Go.

Each language needs its own feasible browser runtime/toolchain. Some
languages may only be partially supported, require a large runtime, or
be impossible to support in a practical and policy-compliant browser
build. Do not promise parity between Web and future Android.

------------------------------------------------------------------------

# PART B --- REPOSITORY AND PACKAGE ARCHITECTURE

## 4. Repository strategy

Use a monorepo so the public package and playground can evolve together.

``` text
polycode/
├── packages/
│   └── polycode/
│       ├── lib/
│       │   ├── polycode.dart
│       │   └── src/
│       │       ├── core/
│       │       ├── models/
│       │       ├── languages/
│       │       ├── engines/
│       │       ├── platform/
│       │       ├── artifacts/
│       │       ├── workspace/
│       │       ├── exceptions/
│       │       └── utils/
│       ├── test/
│       ├── example/
│       ├── web/
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       ├── README.md
│       ├── CHANGELOG.md
│       └── LICENSE
│
├── apps/
│   └── playground/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app/
│       │   ├── core/
│       │   ├── features/
│       │   │   ├── editor/
│       │   │   ├── execution/
│       │   │   ├── layouts/
│       │   │   ├── themes/
│       │   │   ├── language_picker/
│       │   │   ├── files/
│       │   │   └── settings/
│       │   └── shared/
│       ├── test/
│       ├── web/
│       ├── pubspec.yaml
│       └── README.md
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── LANGUAGE_ENGINE_MATRIX.md
│   ├── SECURITY.md
│   ├── RUNTIME_LICENSES.md
│   ├── WEB_DEPLOYMENT.md
│   ├── UI_UX_SPEC.md
│   └── IMPLEMENTATION_STATUS.md
│
├── tool/
│   ├── verify_package.sh
│   ├── verify_web.sh
│   └── runtime_size_report.dart
│
├── .github/
│   └── workflows/
│       ├── package_ci.yml
│       └── deploy_playground.yml
│
├── melos.yaml                 # Optional; only if workspace tooling is useful
├── README.md
└── LICENSE
```

Keep compiler/runtime source and large generated binaries out of the
Dart `lib/` source tree. Store build scripts and runtime integration
assets in clearly documented locations. Do not commit generated
artifacts unless required and legally redistributable.

## 5. Public package identity

-   Package name: `polycode`
-   Import: `package:polycode/polycode.dart`
-   Initial version: `0.1.0` only after the MVP is genuinely functional.
-   License: choose a project license (MIT is a reasonable default for
    PolyCode's own code), but do not assume third-party compiler/runtime
    assets use the same license.
-   Repository: use the actual GitHub URL; never leave placeholder URLs
    in a release.
-   Description must not claim all languages/platforms are supported
    until verified.

## 6. Package dependency policy

Start with the smallest possible dependency set.

Potential dependencies, to be verified against current stable releases
before use:

### Core package

-   `flutter` SDK only if the package genuinely needs Flutter plugin
    integration; otherwise prefer a pure Dart core package.
-   `plugin_platform_interface` only if a platform-interface package is
    actually used.
-   `meta` only if annotations are needed and not already available
    through SDK dependencies.
-   Avoid depending on a UI editor package from the core compiler
    package.

### Development dependencies

-   `flutter_test`
-   `flutter_lints`
-   `mocktail` or another test mock library only if useful.
-   `pigeon` only if type-safe Flutter/native channel bindings are
    needed later.
-   `ffigen` only when generating bindings for native C APIs.
-   `melos` only if monorepo commands justify it.

### Playground dependencies

-   `flutter_bloc`
-   `equatable` only if it materially simplifies immutable BLoC state
    equality; otherwise use Dart records/freezed-style approach only if
    justified.
-   `shared_preferences` for simple theme/layout preferences, if
    supported and useful.
-   `flutter_code_editor`, CodeMirror 6 interop, or Monaco Editor
    integration: evaluate carefully. Pick one editor strategy after a
    spike; do not add multiple editors without a product reason.
-   `file_picker` is optional and must be checked for Web compatibility
    and browser limitations.
-   Do not use a package that requires a remote service for code
    execution.

### Runtime integrations

Investigate independently and record results in
`docs/LANGUAGE_ENGINE_MATRIX.md`:

-   QuickJS or another embeddable JavaScript engine.
-   CPython embedding/WASM build.
-   Clang/LLVM or WASM-targeted C/C++ toolchain.
-   Java compiler plus a compatible JVM/WASM runtime.
-   Kotlin compiler plus a compatible runtime.
-   Dart source compilation/execution feasibility.
-   Rust `wasm32` toolchain and browser execution.
-   Go `js/wasm` or WASI toolchain and browser execution.

For every candidate record: upstream project, version, license,
supported architectures, browser feasibility, runtime size, offline
behavior, security limitations, maintenance health, and whether binary
redistribution is allowed.

Do not select a runtime merely because a Pub.dev wrapper exists. Verify
the underlying engine actually runs the requested source language.

## 7. Package architecture

Use clean boundaries:

``` text
Public Dart API
      |
Execution Manager
      |
Language Registry ---- Platform Capabilities
      |
Engine Registry
      |
Language Engine Adapter
      |
Platform Runtime Bridge
      |
Embedded Runtime / WASM Runtime
```

The core must not import a specific language engine directly. Engines
register through an internal registry or an explicit engine registration
API.

------------------------------------------------------------------------

# PART C --- PUBLIC DART API CONTRACT

## 8. Public API goals

The API should be intuitive, asynchronous, typed, and
platform-transparent.

Illustrative target usage:

``` dart
import 'package:polycode/polycode.dart';

final polycode = PolyCode();

final result = await polycode.execute(
  ExecutionRequest(
    language: PolyLanguage.python,
    source: 'print("Hello PolyCode")',
  ),
);

print(result.stdout);
print(result.stderr);

await polycode.dispose();
```

The exact implementation must be consistent across all models and tests.
Do not expose internal native handles to normal package users.

## 9. Required public types

Implement and document:

-   `PolyCode`
-   `PolyCodeConfig`
-   `PolyLanguage`
-   `ExecutionRequest`
-   `SourceFile`
-   `ExecutionConfig`
-   `ExecutionResult`
-   `CompilationResult`
-   `ExecutionArtifact`
-   `Diagnostic`
-   `LanguageInfo`
-   `PlatformCapabilities`
-   `EngineCapabilities`
-   `ExecutionEvent`
-   `ExecutionMode`
-   `LanguageStatus`
-   `PolyPlatform`
-   typed exception classes

### Language enum

``` dart
enum PolyLanguage {
  c,
  cpp,
  python,
  javascript,
  java,
  kotlin,
  dart,
  rust,
  go,
}
```

### Status enum

``` dart
enum LanguageStatus {
  available,
  experimental,
  requiresRuntime,
  planned,
  unsupported,
}
```

A language is `available` only when the current platform has a working
registered engine and verified execution test.

### Execution request

The request should support:

-   language
-   source
-   optional entry filename
-   multiple source files
-   stdin
-   command-line arguments
-   compiler options (validated and engine-specific)
-   execution configuration

Never accept arbitrary shell command strings from application code and
pass them to a shell. Use argument arrays and safe process APIs where
native processes are permitted.

### Execution configuration

Support where enforceable:

-   timeout
-   maximum stdout/stderr output bytes
-   memory limit
-   stdin
-   workspace policy
-   network permission
-   filesystem permission
-   cleanup behavior
-   cancellation token or cancellation API

Every capability must be reported honestly. If a runtime cannot enforce
a setting, return a capability limitation or a typed error rather than
silently ignoring it.

### Execution result

Return normalized:

-   stdout
-   stderr
-   nullable exit code
-   success
-   timed-out flag
-   execution duration
-   whether compilation occurred
-   diagnostics
-   optional artifact metadata
-   optional structured error

### Compilation result

Return:

-   success
-   diagnostics
-   compiler stdout/stderr
-   duration
-   artifact (only on successful compilation)
-   engine and compiler version metadata

### Execution events

`executeStream()` should emit typed lifecycle events such as:

-   queued
-   preparing
-   compiling
-   running
-   stdout
-   stderr
-   completed
-   failed
-   cancelled

Do not buffer unlimited output in memory. Apply configured output
limits.

## 10. Engine interface

Create an internal interface that separates interpreter and compiler
capabilities.

Conceptual design:

``` dart
abstract interface class PolyCodeEngine {
  PolyLanguage get language;

  Future<EngineCapabilities> getCapabilities();

  Future<ExecutionResult> execute(
    ExecutionRequest request,
  );

  Future<void> dispose();
}
```

Compiled engines may implement an additional compiler interface:

``` dart
abstract interface class PolyCodeCompilerEngine
    implements PolyCodeEngine {
  Future<CompilationResult> compile(
    ExecutionRequest request,
  );

  Future<ExecutionResult> run(
    ExecutionArtifact artifact,
    ExecutionConfig config,
  );
}
```

Do not force an interpreter to implement a meaningless compile
operation. The public facade may offer `compile()`, but it must return a
typed unsupported-operation result/error when the engine does not
support compilation.

## 11. Artifacts and workspace

-   Artifacts must be opaque to package consumers except for documented
    metadata.
-   Do not expose unsafe absolute filesystem paths as public stable API.
-   Keep temporary files within an app-controlled workspace.
-   Clean temporary artifacts according to configuration.
-   Support multiple source files and deterministic entry-file handling.
-   Define artifact lifecycle and disposal.
-   Do not persist user source unless the caller explicitly requests it.

------------------------------------------------------------------------

# PART D --- LANGUAGE ENGINE PLAN

## 12. Initial language matrix

The nine languages are requested product targets. Maintain a matrix with
one row per language and per platform.

For each engine document:

-   chosen implementation
-   version
-   license
-   browser compatibility
-   WebAssembly target availability
-   Android compatibility (future)
-   compile/interpret behavior
-   required assets
-   estimated compressed/uncompressed size
-   offline behavior
-   test status
-   known limitations

### Initial strategy

  -----------------------------------------------------------------------
  Language                Candidate direction     Notes
  ----------------------- ----------------------- -----------------------
  JavaScript              QuickJS/WASM or         Start with a small,
                          browser-compatible JS   real execution engine
                          runtime                 

  Python                  CPython WASM build or   Validate
                          verified browser Python standard-library
                          runtime                 coverage and size

  C                       WASM-targeted Clang     Compile to WASM and
                          toolchain               execute in a sandboxed
                                                  runtime

  C++                     WASM-targeted Clang     Standard library
                          toolchain               support and binary size
                                                  need investigation

  Rust                    `wasm32` target         Rust code may compile
                                                  to WASM; define
                                                  supported target/API
                                                  subset

  Go                      `js/wasm` or WASI       Verify browser
                                                  glue/runtime and Go
                                                  version constraints

  Java                    Java compiler plus      High feasibility risk;
                          feasible browser        do not claim support
                          JVM/WASM runtime        prematurely

  Kotlin                  Kotlin compiler plus    Kotlin/JVM and
                          compatible runtime      Kotlin/JS are different
                                                  targets

  Dart                    Investigate Dart        Flutter's own compiled
                          compiler/runtime        runtime is not a
                          options                 general Dart source
                                                  evaluator
  -----------------------------------------------------------------------

### Recommended delivery order

1.  JavaScript
2.  Python
3.  C
4.  C++
5.  Rust
6.  Go
7.  Java
8.  Kotlin
9.  Dart

This order is a delivery recommendation, not a claim that later engines
are impossible. The agent must run technical spikes and update the order
if evidence supports a better choice.

### Engine spike acceptance criteria

Before implementing a language engine, prove a small standalone
prototype that:

1.  Executes a "Hello World" program locally in a browser.
2.  Accepts stdin where the runtime supports it.
3.  Captures stdout and stderr separately where possible.
4.  Returns a meaningful exit status or documents why it cannot.
5.  Can be stopped or bounded.
6.  Works without network after its runtime assets are cached.
7.  Does not require a server.
8.  Has a documented runtime license.
9.  Has measured asset size.
10. Passes on the supported browser matrix.

------------------------------------------------------------------------

# PART E --- SECURITY AND RESOURCE MANAGEMENT

## 13. Security requirements

PolyCode executes user-provided code. Treat every source program as
untrusted.

### Web

-   Run code in a Web Worker, not the Flutter UI thread.
-   Use WASM runtime isolation where possible.
-   Restrict imported host functions.
-   Do not expose browser DOM, cookies, local storage, or application
    secrets to executed code.
-   Do not expose arbitrary network access.
-   Apply memory and execution budgets supported by the runtime.
-   Bound stdout/stderr output.
-   Terminate workers on timeout/cancellation.
-   Use a restrictive Content Security Policy where hosting
    configuration allows.
-   Validate file names and prevent path traversal in virtual
    filesystems.
-   Do not execute user source through `eval()` in the application
    origin as a substitute for a sandbox.

### Future Android

-   Do not assume Dart isolates sandbox native code.
-   Do not execute arbitrary native binaries with unrestricted app
    permissions.
-   Prefer a constrained WASM runtime for untrusted source.
-   Restrict filesystem access to a dedicated workspace.
-   Apply CPU/time/output limits where the runtime supports them.
-   Document limitations imposed by Android process and app sandboxing.

### Honest security model

A browser Worker improves responsiveness but is not by itself a complete
security boundary. WASM is safer when imports and host capabilities are
restricted, but runtime vulnerabilities and resource exhaustion remain
possible. Never advertise PolyCode as "100% secure".

------------------------------------------------------------------------

# PART F --- FLUTTER WEB PLAYGROUND

## 14. Application vision

Build a polished, responsive, browser-based coding playground using
Flutter Web and the public `polycode` package.

The Playground must feel like a real developer tool, not a basic demo
form.

It must provide three primary workspace layouts:

1.  **Competitive Programming layout** --- problem/task panel, code
    editor, custom input, output, sample tests, run and submit-style
    local test actions.
2.  **Code Block layout** --- compact embeddable-style code snippet with
    language label, copy button, run button, optional input/output, and
    expandable result.
3.  **VS Code-style layout** --- file explorer, tabs, editor,
    terminal/output panel, status bar, resizable panels.

These are three views of the same editor/execution workspace. Switching
layouts must preserve source code, language, input, output history, and
settings.

Do not use the name or branding of third-party products in a way that
implies affiliation. "VS Code-style" means a familiar IDE layout, not a
copy of proprietary branding.

## 15. UI/UX quality requirements

-   Modern, clean, professional developer-tool appearance.
-   Dark and light themes.
-   At least two polished built-in theme presets (for example, a neutral
    dark theme and a clean light theme).
-   Theme tokens centralized; do not hard-code colors in individual
    widgets.
-   Responsive desktop, tablet, and mobile browser layouts.
-   Keyboard accessible controls and visible focus states.
-   Clear empty, loading, running, success, error, unsupported, and
    offline states.
-   Avoid excessive gradients, oversized cards, and unnecessary
    decoration.
-   Use consistent spacing, typography, border radii, and iconography.
-   Support system theme preference and manual override.
-   Persist theme, selected layout, and non-sensitive preferences
    locally.
-   Never persist source code by default without user consent or an
    explicit local-save setting.

## 16. Main application shell

The desktop app should have:

### Top application bar

-   PolyCode logo/name
-   Language selector
-   Layout selector
-   Theme selector
-   Run button
-   Stop button (enabled only while execution is active)
-   Settings/menu

### Main workspace

The workspace changes according to selected layout.

### Bottom/status area

-   Execution status
-   Selected language and engine/version
-   Duration
-   Exit status
-   Runtime capability warnings
-   Offline/cache status when relevant

### Output panel

Tabs or segmented sections:

-   Output
-   Input
-   Errors
-   Diagnostics
-   Test Results (competitive layout)

Avoid putting all logs into one undifferentiated text area.

------------------------------------------------------------------------

## 17. Layout A --- Competitive Programming View

This view is inspired by competitive programming IDEs.

### Desktop layout

``` text
┌─────────────────────────────────────────────────────────────┐
│ PolyCode | Language | Theme | Layout | Run | Stop            │
├──────────────────────┬──────────────────────────────────────┤
│ Problem / Task       │ Code Editor                           │
│                      │                                        │
│ Title                │ 1  #include <iostream>                 │
│ Description          │ 2  int main() {                        │
│ Constraints          │ 3    ...                               │
│ Sample Input         │                                        │
│ Sample Output        │                                        │
│                      │                                        │
├──────────────────────┴──────────────────────────────────────┤
│ Custom Input | Output | Errors | Test Results                │
├─────────────────────────────────────────────────────────────┤
│ stdin area / execution output / diagnostics                  │
└─────────────────────────────────────────────────────────────┘
```

### Features

-   Optional problem/task statement panel.
-   Problem title and Markdown description.
-   Constraints and examples.
-   Sample input and expected output.
-   Code editor.
-   Custom stdin input area.
-   Run button.
-   Run Sample Tests action.
-   Local "Submit" action that means run against locally configured test
    cases only; never imply a remote judge.
-   Test result list with pass/fail, expected output, actual output, and
    diff.
-   Execution time and exit code.
-   Resizable statement/editor and editor/output split.
-   On narrow screens, use tabs or stacked panels rather than squeezing
    columns.

### Competitive programming test model

Create a local test-case model:

-   name
-   stdin
-   expected stdout
-   optional comparison mode (exact, trim trailing whitespace,
    normalized whitespace)
-   result status
-   actual stdout/stderr
-   duration

Do not claim competitive ranking, remote judging, or hidden test access.

------------------------------------------------------------------------

## 18. Layout B --- Code Block View

This is a compact, shareable code-snippet runner view.

### Example visual structure

``` text
┌────────────────────────────────────────────┐
│ Python                         Copy  Run   │
├────────────────────────────────────────────┤
│ 1  print("Hello PolyCode")                 │
│ 2  print(2 + 3)                            │
├────────────────────────────────────────────┤
│ Output                                     │
│ Hello PolyCode                             │
│ 5                                          │
└────────────────────────────────────────────┘
```

### Features

-   Language badge/selector.
-   Syntax-highlighted code editor.
-   Copy code.
-   Run code.
-   Expand/collapse output.
-   Optional stdin input.
-   Error/diagnostic display.
-   Compact and expanded modes.
-   Read-only mode for documentation snippets.
-   Configurable height.
-   Responsive behavior.
-   Optional line numbers and wrapping.

The Code Block layout must reuse the same editor and execution BLoCs; do
not create a separate compiler implementation.

------------------------------------------------------------------------

## 19. Layout C --- VS Code-style IDE View

### Desktop structure

``` text
┌──────────────────────────────────────────────────────────────┐
│ Menu / Workspace / Language / Run / Theme                    │
├──────┬───────────────────────────────┬───────────────────────┤
│      │ File Tabs                     │                       │
│ Side │                               │                       │
│ bar  │ Code Editor                   │ Minimap (optional)    │
│      │                               │                       │
│ Files│                               │                       │
│      │                               │                       │
├──────┴───────────────────────────────┴───────────────────────┤
│ Terminal | Output | Problems | Debug Info                    │
├──────────────────────────────────────────────────────────────┤
│ Terminal / stdin / stdout / stderr                            │
├──────────────────────────────────────────────────────────────┤
│ Status Bar: Language | Engine | Encoding | Duration           │
└──────────────────────────────────────────────────────────────┘
```

### Features

-   File explorer.
-   New file, rename, delete, and folder operations in a virtual project
    workspace.
-   Multiple editor tabs.
-   Dirty-file indicator.
-   Syntax highlighting.
-   Line numbers.
-   Indentation and bracket matching.
-   Find in file.
-   Keyboard shortcuts.
-   Terminal/output panel (not a full OS shell).
-   Problems/diagnostics panel.
-   Resizable sidebar and bottom panel.
-   Restore workspace layout.
-   Multiple source files for languages that support them.
-   Save/load project files locally with explicit user action.
-   Import/export source files where browser APIs permit.
-   No claim that the terminal is a system shell; it is a PolyCode
    execution console.

### Editor technology decision

Do a short technical spike before choosing an editor:

-   Evaluate CodeMirror 6 integration for Web, including Flutter interop
    and language modes.
-   Evaluate Monaco integration if the project needs a richer IDE
    experience and its bundle size/performance is acceptable.
-   Evaluate existing Flutter code editor packages only if they
    genuinely support Web, required syntax highlighting, keyboard
    behavior, and custom themes.
-   Pick one primary editor engine and wrap it behind a `CodeEditor`
    widget/API.
-   Do not implement a text editor from scratch.
-   Ensure the editor works with the selected Flutter Web renderer and
    current supported browsers.

The chosen editor must support dynamic language changes, theme changes,
text selection, cursor/selection state, keyboard shortcuts, and
large-file performance appropriate to the target.

------------------------------------------------------------------------

# PART G --- THEME SYSTEM

## 20. Theme requirements

Implement a dedicated theme system.

### Built-in themes

-   `PolyCodeDarkTheme`
-   `PolyCodeLightTheme`

Optional future themes:

-   High Contrast
-   Monokai-inspired
-   GitHub-inspired

Do not copy proprietary theme assets without checking their license.

### Theme tokens

Define centralized tokens for:

-   app background
-   panel background
-   elevated panel
-   editor background
-   primary text
-   secondary text
-   muted text
-   border/divider
-   accent
-   success
-   warning
-   error
-   selection
-   line number
-   cursor
-   syntax token colors
-   terminal colors

### Theme behavior

-   System / Light / Dark preference.
-   Manual theme selection.
-   Persist selected theme locally.
-   Theme updates must apply to app shell, editor, terminal, dialogs,
    dropdowns, and all layouts.
-   Avoid hard-coded colors in feature widgets.
-   Ensure readable contrast and focus indicators.

------------------------------------------------------------------------

# PART H --- BLoC STATE MANAGEMENT

## 21. BLoC architecture

Use `flutter_bloc` for the Playground application. Keep BLoC out of the
core `polycode` package.

Recommended feature BLoCs:

``` text
features/
├── editor/
│   ├── bloc/
│   │   ├── editor_bloc.dart
│   │   ├── editor_event.dart
│   │   └── editor_state.dart
│   └── widgets/
│
├── execution/
│   ├── bloc/
│   │   ├── execution_bloc.dart
│   │   ├── execution_event.dart
│   │   └── execution_state.dart
│   └── widgets/
│
├── layouts/
│   ├── bloc/
│   │   ├── layout_bloc.dart
│   │   ├── layout_event.dart
│   │   └── layout_state.dart
│
├── themes/
│   ├── bloc/
│   │   ├── theme_bloc.dart
│   │   ├── theme_event.dart
│   │   └── theme_state.dart
│
├── language_picker/
│   └── bloc/
│
├── files/
│   └── bloc/
│
└── settings/
    └── bloc/
```

## 22. BLoC responsibilities

### EditorBloc

Owns:

-   Current source.
-   Current language.
-   Cursor and selection metadata if required.
-   Open files and active file.
-   Dirty/clean state.
-   Editor settings (font size, tab size, wrapping).

Events:

-   `SourceChanged`
-   `LanguageChanged`
-   `FileOpened`
-   `FileClosed`
-   `FileCreated`
-   `FileRenamed`
-   `FileDeleted`
-   `ActiveFileChanged`
-   `EditorSettingsChanged`

### ExecutionBloc

Owns:

-   Execution lifecycle.
-   Current request.
-   stdout/stderr.
-   stdin.
-   diagnostics.
-   compile status.
-   runtime status.
-   execution history.
-   test-case results.
-   timeout/cancellation state.

Events:

-   `RunRequested`
-   `CompileRequested`
-   `StopRequested`
-   `StdinChanged`
-   `ClearOutputRequested`
-   `RunSampleTestsRequested`
-   `ExecutionEventReceived`

Execution must call the `polycode` package facade. Do not put compiler
implementation in the BLoC.

### LayoutBloc

Owns:

-   selected layout (`competitive`, `codeBlock`, `ide`)
-   panel visibility
-   sidebar visibility
-   panel sizes
-   responsive layout mode

Switching layout must not clear editor source or execution history.

### ThemeBloc

Owns:

-   system/light/dark mode
-   selected theme preset
-   persisted preference
-   editor/terminal theme mapping

### LanguageBloc (or LanguagePickerBloc)

Owns:

-   available languages for the current platform
-   selected language
-   engine version and status
-   capability warnings
-   disabled/unavailable language reasons

### FileWorkspaceBloc

Owns virtual project files and local import/export actions. Avoid
duplicating active editor source; establish one source of truth and
synchronize through explicit events.

## 23. BLoC design rules

-   Use immutable states.
-   Keep UI widgets thin.
-   Use repositories/services for persistence and package calls.
-   Avoid giant "AppBloc" containing all features.
-   Avoid duplicate source-of-truth state.
-   Handle rapid repeated Run presses safely.
-   Cancel or invalidate stale results when a newer execution supersedes
    an older one.
-   Keep execution off the Flutter UI thread through the underlying
    engine/worker design.
-   Test BLoCs with deterministic fake repositories/engines.
-   Use `BlocProvider`, `MultiBlocProvider`, `BlocBuilder`,
    `BlocListener`, and `BlocSelector` appropriately.

------------------------------------------------------------------------

# PART I --- APP DATA FLOW AND USER EXPERIENCE

## 24. Run flow

1.  User selects a language.
2.  LanguageBloc loads actual platform capabilities from `PolyCode`.
3.  User edits code.
4.  User enters optional stdin.
5.  User presses Run.
6.  ExecutionBloc validates that an engine is available.
7.  ExecutionBloc creates an `ExecutionRequest`.
8.  `PolyCode.execute()` is called.
9.  Lifecycle events update the UI.
10. stdout/stderr/diagnostics are displayed in their respective panels.
11. Result metadata is shown in status bar.
12. User can clear output or run again.

If the language is unsupported, show an explanatory state and do not
call a fake engine.

## 25. User-facing states

Every relevant screen must handle:

-   Initial / no code
-   Loading runtimes
-   Runtime ready
-   Runtime unavailable
-   Runtime download/cache preparation (only if applicable)
-   Offline
-   Compiling
-   Running
-   Completed successfully
-   Completed with non-zero exit
-   Compile error
-   Runtime error
-   Timeout
-   Cancelled
-   Output limit reached
-   Unsupported language/platform
-   Internal engine error

Do not display "Compiled successfully" for an interpreted language. Use
neutral lifecycle labels where appropriate.

------------------------------------------------------------------------

# PART J --- LOCAL STORAGE AND OFFLINE BEHAVIOR

## 26. Local persistence

Persist only user preferences by default:

-   theme
-   layout
-   editor font size
-   panel visibility/sizes
-   selected language

Source code persistence must be explicit:

-   Save project
-   Open project
-   Import files
-   Export files
-   Optional local autosave only after the user enables it

For Web:

-   Use IndexedDB or a suitable local persistence layer for explicit
    projects and runtime cache metadata.
-   Use browser Cache Storage/service worker for app/runtime assets
    where feasible.
-   Do not assume browser storage is permanent; it can be cleared by the
    browser.
-   Handle storage quota errors.
-   Do not store secrets in browser storage.

## 27. Offline-first requirements

-   The Playground shell should load offline after a successful
    service-worker cache.
-   Runtime assets must be same-origin/static assets or otherwise
    explicitly documented.
-   The first visit may require downloading large runtime assets.
-   Show per-runtime asset size and cache status where practical.
-   Never claim "offline ready" before the runtime assets needed for the
    selected language are cached.
-   A language must not appear ready if its engine files are missing.

------------------------------------------------------------------------

# PART K --- GITHUB PAGES DEPLOYMENT

## 28. Deployment requirements

Host the Flutter Web Playground on GitHub Pages.

-   Use a GitHub Actions workflow.
-   Build Flutter Web in release mode.
-   Set the correct base href for the repository path (or use a custom
    domain).
-   Publish the generated `build/web` directory using GitHub Pages
    deployment.
-   Ensure runtime WASM assets are copied to the correct output
    location.
-   Configure correct MIME types for `.wasm` and worker files where
    possible.
-   Test relative asset paths.
-   Test deep links and refresh behavior.
-   Verify browser console has no missing asset or MIME errors.
-   Do not rely on server rewrite rules unavailable on GitHub Pages.
-   Add a 404 fallback strategy if the app uses path-based routes.
-   Document how to deploy both repository Pages and custom-domain
    Pages.

### Deployment acceptance criteria

1.  GitHub Actions completes successfully.
2.  Public URL loads the Flutter app.
3.  Flutter assets load under the GitHub repository subpath.
4.  WASM and worker files load correctly.
5.  Refreshing the root page works.
6.  All supported local engines run without backend calls.
7.  No external compiler API request is made.
8.  The offline/PWA behavior is tested separately.

------------------------------------------------------------------------

# PART L --- TESTING AND QUALITY

## 29. Package tests

### Unit tests

-   Language enum/registry.
-   Engine registration and lookup.
-   Capability mapping.
-   Request validation.
-   Configuration validation.
-   Result normalization.
-   Artifact lifecycle.
-   Error conversion.
-   Timeout handling.
-   Output truncation.
-   Disposal.

### Integration tests

For every engine/platform combination advertised as available:

-   Hello World.
-   stdin.
-   stdout/stderr.
-   non-zero exit.
-   compile error (compiled languages).
-   runtime error.
-   timeout.
-   large output limit.
-   multiple files where supported.
-   offline execution after assets are cached.

### Playground tests

-   Layout switching preserves state.
-   Theme switching updates all panels.
-   Language switching updates editor mode.
-   Run button state.
-   Stop/cancel behavior.
-   Input/output tabs.
-   Test-case pass/fail.
-   File tab switching.
-   Project import/export.
-   Responsive layouts.
-   Keyboard shortcuts.
-   Accessibility smoke tests.

### CI

Use GitHub Actions to run:

-   `dart format --output=none --set-exit-if-changed .`
-   `flutter analyze`
-   `flutter test`
-   package validation / `dart pub publish --dry-run`
-   Flutter Web release build
-   package and app integration tests where practical

Do not publish automatically from every commit. Use a reviewed release
tag and a deliberate release workflow.

------------------------------------------------------------------------

# PART M --- PHASE-BY-PHASE IMPLEMENTATION ROADMAP

## Phase 0 --- Repository reconnaissance and technical feasibility

**Goal:** Confirm toolchain, architecture, and runtime feasibility
before substantial coding.

Tasks:

-   Inspect installed Flutter/Dart versions.
-   Create monorepo structure.
-   Create package and Playground skeletons.
-   Research runtime candidates and licenses.
-   Build tiny browser prototypes for JavaScript, Python, and C/C++
    execution.
-   Record runtime size and browser compatibility.
-   Create `docs/LANGUAGE_ENGINE_MATRIX.md`.
-   Create `docs/SECURITY.md`.
-   Create `docs/IMPLEMENTATION_STATUS.md`.

Acceptance:

-   Both package and Playground skeleton compile.
-   No runtime is claimed supported without a proof-of-concept.
-   The initial language/platform matrix is documented.
-   Third-party licenses are recorded.

## Phase 1 --- Pub.dev core package foundation

**Goal:** Build a stable, testable SDK architecture without real
compiler engines yet.

Tasks:

-   Create public API and models.
-   Create engine interfaces and registry.
-   Create language registry for all nine requested languages.
-   Create capability/status model.
-   Create execution manager.
-   Create artifact and workspace abstractions.
-   Create typed exceptions.
-   Create fake engine strictly for unit tests.
-   Add package README and example.
-   Add unit tests and static analysis.

Acceptance:

-   Package imports from an example Flutter app.
-   All public API contracts compile.
-   Fake engine lifecycle tests pass.
-   Unsupported engines are never advertised as available.
-   `flutter analyze` and `flutter test` pass.
-   `dart pub publish --dry-run` succeeds when package metadata is
    complete.

## Phase 2 --- First real browser engine: JavaScript

**Goal:** Prove the entire local execution pipeline using a real
JavaScript engine.

Tasks:

-   Select and license-check QuickJS or another appropriate engine.
-   Build browser-compatible runtime assets.
-   Integrate a Web Worker.
-   Implement stdin/stdout/stderr behavior where feasible.
-   Add timeout/cancel and output limits.
-   Add runtime version metadata.
-   Add offline cache behavior.
-   Add real browser integration tests.

Acceptance:

-   JavaScript Hello World runs locally in the browser.
-   Runtime errors are visible.
-   Long-running code can be terminated.
-   Output limits work.
-   No backend/API request is used.
-   Execution works offline after runtime assets are cached.

## Phase 3 --- Python browser engine

**Goal:** Add a real Python runtime.

Tasks:

-   Evaluate CPython WASM and alternative maintained browser Python
    runtimes.
-   Verify standard-library subset and import behavior.
-   Verify stdin/stdout/stderr.
-   Measure compressed and uncompressed asset sizes.
-   Implement Worker-based execution and cancellation.
-   Document unsupported native extensions.

Acceptance:

-   Python Hello World and arithmetic tests pass.
-   stdin works if supported by the selected runtime.
-   Errors are normalized.
-   Offline cached execution works.
-   Runtime size and limitations are documented.

## Phase 4 --- C and C++ Web compilation

**Goal:** Real C/C++ compilation and execution in the browser.

Tasks:

-   Evaluate Clang/LLVM WebAssembly toolchain and standard-library
    support.
-   Compile source to WASM or another browser-executable artifact.
-   Execute the artifact in a restricted WASM runtime.
-   Support compiler diagnostics.
-   Support multiple source files where feasible.
-   Support stdin and bounded output.
-   Measure compiler and runtime assets separately.
-   Avoid exposing unrestricted host imports.

Acceptance:

-   C Hello World compiles and runs.
-   C++ Hello World compiles and runs.
-   Syntax errors are returned as diagnostics.
-   Runtime output is captured.
-   Timeout and output limits work.
-   No backend is used.

## Phase 5 --- Playground MVP

**Goal:** Build the first usable Flutter Web compiler interface using
the public package.

Tasks:

-   Create application shell.
-   Integrate BLoC architecture.
-   Integrate one selected code editor technology.
-   Add language selector with actual availability states.
-   Add source editor.
-   Add stdin panel.
-   Add stdout/stderr/diagnostics panels.
-   Add Run/Stop/Clear actions.
-   Add loading, error, unsupported, and offline states.
-   Add dark and light themes.
-   Add responsive layout.

Acceptance:

-   JavaScript and Python work through the UI when their engines are
    ready.
-   UI remains responsive during execution.
-   Run/Stop lifecycle works.
-   Theme changes apply consistently.
-   No fake output is displayed.

## Phase 6 --- Three workspace layouts

**Goal:** Complete the three requested user experiences.

Tasks:

### Competitive Programming view

-   Problem statement panel.
-   Constraints and sample examples.
-   Code editor.
-   Custom input.
-   Local sample test cases.
-   Expected vs actual output.
-   Pass/fail status.
-   Resizable panels.

### Code Block view

-   Compact code card.
-   Language badge.
-   Copy action.
-   Run action.
-   Expandable output.
-   Optional input.
-   Read-only mode.
-   Configurable height.

### VS Code-style IDE view

-   File explorer.
-   Tabs.
-   Multiple source files.
-   Editor settings.
-   Find in file.
-   Terminal/output panel.
-   Problems panel.
-   Resizable sidebar and bottom panel.
-   Status bar.
-   Local project import/export.

Acceptance:

-   Layout switching preserves code, language, input, and results.
-   Each layout is usable on desktop and responsive on small screens.
-   All layouts use the same execution service and BLoCs.

## Phase 7 --- Themes and user preferences

**Goal:** Deliver a complete theme and customization system.

Tasks:

-   Dark theme.
-   Light theme.
-   System theme mode.
-   Central design tokens.
-   Editor syntax themes.
-   Terminal themes.
-   Persist theme selection.
-   Persist selected layout and editor preferences.
-   Contrast/accessibility review.

Acceptance:

-   All three layouts fully support light and dark modes.
-   No hard-coded inconsistent colors remain.
-   Theme survives page reload.
-   System mode follows browser preference.

## Phase 8 --- Rust and Go browser engines

**Goal:** Investigate and implement Rust/Go where practical.

Tasks:

-   Evaluate Rust WASM target and browser runtime requirements.
-   Evaluate Go `js/wasm` or WASI route.
-   Build proof-of-concepts.
-   Document standard-library and system-call restrictions.
-   Integrate only after tests pass.

Acceptance:

-   A real program compiles/runs locally.
-   Limitations and runtime size are documented.
-   Offline execution works after caching.
-   No unsupported behavior is advertised.

## Phase 9 --- Java and Kotlin feasibility / integration

**Goal:** Investigate real local browser compilation and execution.

Tasks:

-   Evaluate Java compiler and browser-compatible JVM/WASM runtime.
-   Evaluate Kotlin/JVM versus Kotlin/JS compiler targets.
-   Define what "Java support" and "Kotlin support" mean for the
    Playground.
-   Build isolated prototypes.
-   Measure asset sizes and startup performance.
-   Implement only a viable and maintainable route.

Acceptance:

-   Actual source compilation/execution is demonstrated.
-   No transpilation-only feature is mislabeled as JVM execution.
-   Unsupported Java/Kotlin features are documented.
-   Platform capability status is accurate.

## Phase 10 --- Dart source execution feasibility

**Goal:** Investigate Dart source compilation/execution independently of
the Flutter Web app runtime.

Tasks:

-   Evaluate supported Dart compiler/runtime embedding options.
-   Determine whether arbitrary Dart source can run in the browser
    without a server.
-   Do not assume the app's own Dart runtime can execute arbitrary
    source.
-   Publish a feasibility report.

Acceptance:

-   Either a real, tested Dart execution engine exists, or Dart is
    clearly marked unsupported/planned with an explanation.
-   No fake Dart execution is implemented.

## Phase 11 --- Polish, performance, accessibility, and offline

Tasks:

-   Runtime lazy loading.
-   Asset compression.
-   Cache versioning and invalidation.
-   Startup performance.
-   Editor large-file performance.
-   Responsive testing.
-   Keyboard navigation.
-   Screen-reader labels.
-   Error reporting without sending source code externally.
-   Browser compatibility matrix.
-   Security review.

Acceptance:

-   No major UI jank during execution.
-   Runtime assets are cached correctly.
-   Offline state is truthful.
-   Layouts work at common desktop/tablet/mobile widths.
-   Accessibility smoke tests pass.

## Phase 12 --- GitHub Pages deployment

Tasks:

-   Add GitHub Actions workflow.
-   Configure Flutter Web base href.
-   Build release bundle.
-   Publish to GitHub Pages.
-   Validate WASM MIME types and worker URLs.
-   Validate repository-subpath routing.
-   Test refresh and deep links.
-   Test runtime execution on deployed URL.
-   Test offline cache after first load.

Acceptance:

-   Public GitHub Pages URL works.
-   All assets load.
-   Supported languages run locally.
-   No backend/API dependency exists.
-   No broken relative URLs or WASM MIME errors.

## Phase 13 --- Pub.dev release

Tasks:

-   Finalize README and usage examples.
-   Add complete API docs.
-   Add CHANGELOG.
-   Add license notices and third-party runtime attribution.
-   Verify package size.
-   Verify minimum Dart/Flutter SDK constraints.
-   Run `flutter analyze`.
-   Run all tests.
-   Run `dart pub publish --dry-run`.
-   Review package score warnings.
-   Publish a deliberate version tag and release.

Acceptance:

-   Package can be installed from Pub.dev.
-   Example app works.
-   Public API documentation is complete.
-   Supported platform/language matrix is accurate.
-   Runtime licenses and size are disclosed.

## Phase 14 --- Future Android application (not now)

Only after the package and Web Playground are stable:

-   Build Android native runtime integration.
-   Evaluate JNI/FFI and WASM runtimes.
-   Verify Android ABI support.
-   Add Android integration tests.
-   Build a separate Flutter Android application using the same package.
-   Review Play Store policies and executable-code restrictions.
-   Prepare store listing and release.

Do not start this phase during the current assignment.

------------------------------------------------------------------------

# PART N --- UI COMPONENT INVENTORY

## 30. Reusable Flutter widgets

Build reusable components:

-   `PolyCodeAppShell`
-   `PolyCodeTopBar`
-   `LanguageSelector`
-   `LayoutSelector`
-   `ThemeSelector`
-   `RunButton`
-   `StopButton`
-   `CodeEditor`
-   `EditorToolbar`
-   `FileExplorer`
-   `EditorTabs`
-   `StdinPanel`
-   `OutputPanel`
-   `StderrPanel`
-   `DiagnosticsPanel`
-   `TestCasesPanel`
-   `ProblemStatementPanel`
-   `TerminalPanel`
-   `StatusBar`
-   `RuntimeStatusBadge`
-   `ExecutionProgressIndicator`
-   `EmptyState`
-   `UnsupportedLanguageView`
-   `OfflineRuntimeNotice`
-   `ResizableSplitView`

Each component must consume BLoC state or explicit immutable inputs. Do
not let widgets instantiate compiler engines directly.

## 31. Responsive behavior

### Desktop

-   Full IDE/competitive layouts.
-   Resizable side panels.
-   Keyboard shortcuts.
-   Multiple editor tabs.

### Tablet

-   Collapsible sidebar.
-   Reduced panel density.
-   Switchable editor/output panels.

### Mobile browser

-   Single-column or tabbed workspace.
-   Editor gets priority.
-   Output/input switch through bottom navigation or tabs.
-   Compact top controls.
-   Do not force desktop split panes into a narrow viewport.

------------------------------------------------------------------------

# PART O --- DEFINITION OF DONE

## 32. Overall product acceptance criteria

The project is considered ready for its first public release only when:

### Package

-   [ ] Public API is documented.
-   [ ] Engine registry works.
-   [ ] Capability detection works.
-   [ ] At least one real language engine is integrated.
-   [ ] No fake engines are advertised.
-   [ ] Tests pass.
-   [ ] Package dry-run succeeds.
-   [ ] Third-party licenses are documented.

### Playground

-   [ ] Built with Flutter Web.
-   [ ] Uses BLoC.
-   [ ] Uses the public PolyCode package.
-   [ ] Has Competitive Programming layout.
-   [ ] Has Code Block layout.
-   [ ] Has VS Code-style IDE layout.
-   [ ] Has light and dark themes.
-   [ ] Has input/output/error/diagnostic panels.
-   [ ] Layout switching preserves state.
-   [ ] Responsive behavior works.
-   [ ] No remote compiler/API dependency.

### Hosting

-   [ ] GitHub Pages deployment works.
-   [ ] WASM and Worker assets load correctly.
-   [ ] Offline behavior is tested.
-   [ ] Refresh/deep-link behavior is correct.
-   [ ] No missing runtime assets.

### Transparency

-   [ ] Language support matrix is accurate.
-   [ ] Runtime size is disclosed.
-   [ ] Browser limitations are documented.
-   [ ] Security limitations are documented.
-   [ ] No false claims about compiler or sandbox support.

------------------------------------------------------------------------

# PART P --- FINAL INSTRUCTIONS TO THE AGENT

Start with **Phase 0**, then complete **Phase 1**.

Do not immediately build all nine language runtimes or the entire
Playground UI before the core package contract is tested.

At the end of Phase 1:

1.  Show the final folder tree.
2.  List all public classes and APIs implemented.
3.  Show dependency decisions and reasons.
4.  Show test output.
5.  Show `flutter analyze` output.
6.  Show Android and Web package/example build results if available.
7.  List every limitation and incomplete item.
8.  Update `docs/IMPLEMENTATION_STATUS.md`.
9.  Stop and wait for review before beginning Phase 2.

The final goal is a genuinely useful, maintainable, open-source Pub.dev
package and a polished local-first Flutter Web coding playground---not a
mock demo and not a cloud compiler wrapper.
