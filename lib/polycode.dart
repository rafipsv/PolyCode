/// PolyCode is a modular, local-first code execution and compilation SDK
/// for Dart and Flutter with no backend dependencies.
library polycode;

// Artifacts
export 'src/artifacts/execution_artifact.dart';

// Core
export 'src/core/engine_registry.dart';
export 'src/core/execution_manager.dart';
export 'src/core/language_registry.dart';
export 'src/core/polycode_config.dart';
export 'src/core/polycode_facade.dart';

// Engines
export 'src/engines/polycode_compiler_engine.dart';
export 'src/engines/polycode_engine.dart';

// Exceptions
export 'src/exceptions/polycode_exception.dart';

// Models
export 'src/models/compilation_result.dart';
export 'src/models/diagnostic.dart';
export 'src/models/engine_capabilities.dart';
export 'src/models/execution_config.dart';
export 'src/models/execution_event.dart';
export 'src/models/execution_mode.dart';
export 'src/models/execution_request.dart';
export 'src/models/execution_result.dart';
export 'src/models/language_info.dart';
export 'src/models/language_status.dart';
export 'src/models/poly_language.dart';
export 'src/models/poly_platform.dart';
export 'src/models/source_file.dart';

// Utilities & Workspace
export 'src/utils/cancellation_token.dart';
export 'src/workspace/workspace_manager.dart';
