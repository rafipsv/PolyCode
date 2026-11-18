import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';

enum ExecutionStatus {
  idle,
  compiling,
  running,
  completed,
  failed,
  cancelled,
}

sealed class ExecutionBlocEvent {
  const ExecutionBlocEvent();
}

class ExecuteRequested extends ExecutionBlocEvent {
  const ExecuteRequested({
    required this.language,
    required this.source,
    this.stdin = '',
  });

  final PolyLanguage language;
  final String source;
  final String stdin;
}

class StopRequested extends ExecutionBlocEvent {
  const StopRequested();
}

class StdinChanged extends ExecutionBlocEvent {
  const StdinChanged(this.stdin);
  final String stdin;
}

class ClearOutputRequested extends ExecutionBlocEvent {
  const ClearOutputRequested();
}

class _StreamEventReceived extends ExecutionBlocEvent {
  const _StreamEventReceived(this.event);
  final ExecutionEvent event;
}

class ExecutionBlocState {
  const ExecutionBlocState({
    this.status = ExecutionStatus.idle,
    this.stdout = '',
    this.stderr = '',
    this.stdin = '',
    this.exitCode,
    this.duration = Duration.zero,
    this.diagnostics = const [],
    this.errorMessage,
  });

  final ExecutionStatus status;
  final String stdout;
  final String stderr;
  final String stdin;
  final int? exitCode;
  final Duration duration;
  final List<Diagnostic> diagnostics;
  final String? errorMessage;

  bool get isRunning =>
      status == ExecutionStatus.running || status == ExecutionStatus.compiling;

  ExecutionBlocState copyWith({
    ExecutionStatus? status,
    String? stdout,
    String? stderr,
    String? stdin,
    int? exitCode,
    Duration? duration,
    List<Diagnostic>? diagnostics,
    String? errorMessage,
  }) {
    return ExecutionBlocState(
      status: status ?? this.status,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      stdin: stdin ?? this.stdin,
      exitCode: exitCode ?? this.exitCode,
      duration: duration ?? this.duration,
      diagnostics: diagnostics ?? this.diagnostics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExecutionBloc extends Bloc<ExecutionBlocEvent, ExecutionBlocState> {
  ExecutionBloc({required this.polycode}) : super(const ExecutionBlocState()) {
    on<ExecuteRequested>(_onExecuteRequested);
    on<StopRequested>(_onStopRequested);
    on<StdinChanged>((event, emit) => emit(state.copyWith(stdin: event.stdin)));
    on<ClearOutputRequested>((event, emit) => emit(state.copyWith(
          stdout: '',
          stderr: '',
          diagnostics: const [],
          exitCode: null,
          status: ExecutionStatus.idle,
        )));
    on<_StreamEventReceived>(_onStreamEventReceived);
  }

  final PolyCode polycode;
  CancellationToken? _activeCancelToken;
  StreamSubscription<ExecutionEvent>? _activeSub;

  Future<void> _onExecuteRequested(
    ExecuteRequested event,
    Emitter<ExecutionBlocState> emit,
  ) async {
    if (state.isRunning) return;

    _activeCancelToken = CancellationToken();
    emit(state.copyWith(
      status: ExecutionStatus.running,
      stdout: '',
      stderr: '',
      diagnostics: const [],
      exitCode: null,
      errorMessage: null,
    ));

    final request = ExecutionRequest(
      language: event.language,
      source: event.source,
      stdin: event.stdin.isNotEmpty ? event.stdin : state.stdin,
    );

    await _activeSub?.cancel();
    final stream = polycode.executeStream(
      request,
      cancelToken: _activeCancelToken,
    );

    final completer = Completer<void>();
    _activeSub = stream.listen(
      (ev) => add(_StreamEventReceived(ev)),
      onError: (err) {
        emit(state.copyWith(
          status: ExecutionStatus.failed,
          errorMessage: err.toString(),
        ));
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  void _onStreamEventReceived(
    _StreamEventReceived event,
    Emitter<ExecutionBlocState> emit,
  ) {
    final ev = event.event;
    if (ev is CompilingExecutionEvent) {
      emit(state.copyWith(status: ExecutionStatus.compiling));
    } else if (ev is RunningExecutionEvent) {
      emit(state.copyWith(status: ExecutionStatus.running));
    } else if (ev is StdoutExecutionEvent) {
      emit(state.copyWith(stdout: state.stdout + ev.chunk));
    } else if (ev is StderrExecutionEvent) {
      emit(state.copyWith(stderr: state.stderr + ev.chunk));
    } else if (ev is CancelledExecutionEvent) {
      emit(state.copyWith(status: ExecutionStatus.cancelled));
    } else if (ev is FailedExecutionEvent) {
      emit(state.copyWith(
        status: ExecutionStatus.failed,
        errorMessage: ev.error.toString(),
        diagnostics: ev.compilationResult?.diagnostics ?? state.diagnostics,
      ));
    } else if (ev is CompletedExecutionEvent) {
      final res = ev.result;
      emit(state.copyWith(
        status:
            res.isSuccess ? ExecutionStatus.completed : ExecutionStatus.failed,
        exitCode: res.exitCode,
        duration: res.duration,
        diagnostics: res.diagnostics,
      ));
    }
  }

  void _onStopRequested(
    StopRequested event,
    Emitter<ExecutionBlocState> emit,
  ) {
    _activeCancelToken?.cancel();
    emit(state.copyWith(status: ExecutionStatus.cancelled));
  }

  @override
  Future<void> close() async {
    await _activeSub?.cancel();
    _activeCancelToken?.cancel();
    return super.close();
  }
}
