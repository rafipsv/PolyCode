import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import 'execution_event.dart';
import 'execution_state.dart';

export 'execution_event.dart';
export 'execution_state.dart';

class ExecutionBloc extends Bloc<ExecutionBlocEvent, ExecutionBlocState> {
  ExecutionBloc({required this.polycode}) : super(const ExecutionBlocState()) {
    on<ExecuteRequested>(_onExecuteRequested);
    on<StopRequested>((_, emit) {
      _activeCancelToken?.cancel();
      emit(state.copyWith(status: ExecutionStatus.cancelled));
    });
    on<StdinChanged>((e, emit) => emit(state.copyWith(stdin: e.stdin)));
    on<ClearOutputRequested>((_, emit) => emit(const ExecutionBlocState()));
    on<StreamEventReceived>(_onStreamEventReceived);
  }

  final PolyCode polycode;
  CancellationToken? _activeCancelToken;
  StreamSubscription<ExecutionEvent>? _activeSub;

  Future<void> _onExecuteRequested(
    ExecuteRequested e,
    Emitter<ExecutionBlocState> emit,
  ) async {
    if (state.isRunning) return;
    _activeCancelToken = CancellationToken();
    emit(state.copyWith(
      status: ExecutionStatus.running,
      stdout: '',
      stderr: '',
      diagnostics: const [],
    ));

    final req = ExecutionRequest(
      language: e.language,
      source: e.source,
      stdin: e.stdin.isNotEmpty ? e.stdin : state.stdin,
    );
    await _activeSub?.cancel();
    final c = Completer<void>();
    _activeSub =
        polycode.executeStream(req, cancelToken: _activeCancelToken).listen(
              (ev) => add(StreamEventReceived(ev)),
              onError: (err) {
                emit(state.copyWith(
                    status: ExecutionStatus.failed, errorMessage: '$err'));
                if (!c.isCompleted) c.complete();
              },
              onDone: () => !c.isCompleted ? c.complete() : null,
            );
    await c.future;
  }

  void _onStreamEventReceived(
    StreamEventReceived event,
    Emitter<ExecutionBlocState> emit,
  ) {
    switch (event.event) {
      case QueuedExecutionEvent() || PreparingExecutionEvent():
        break;
      case CompilingExecutionEvent():
        emit(state.copyWith(status: ExecutionStatus.compiling));
      case RunningExecutionEvent():
        emit(state.copyWith(status: ExecutionStatus.running));
      case StdoutExecutionEvent(:final chunk):
        emit(state.copyWith(stdout: state.stdout + chunk));
      case StderrExecutionEvent(:final chunk):
        emit(state.copyWith(stderr: state.stderr + chunk));
      case CancelledExecutionEvent():
        emit(state.copyWith(status: ExecutionStatus.cancelled));
      case FailedExecutionEvent(:final error, :final compilationResult):
        emit(state.copyWith(
          status: ExecutionStatus.failed,
          errorMessage: error.toString(),
          diagnostics: compilationResult?.diagnostics ?? state.diagnostics,
        ));
      case CompletedExecutionEvent(:final result):
        emit(state.copyWith(
          status: result.isSuccess
              ? ExecutionStatus.completed
              : ExecutionStatus.failed,
          exitCode: result.exitCode,
          duration: result.duration,
          diagnostics: result.diagnostics,
        ));
    }
  }

  @override
  Future<void> close() async {
    await _activeSub?.cancel();
    _activeCancelToken?.cancel();
    return super.close();
  }
}
