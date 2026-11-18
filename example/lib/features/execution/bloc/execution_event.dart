import 'package:polycode/polycode.dart';

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

class StreamEventReceived extends ExecutionBlocEvent {
  const StreamEventReceived(this.event);
  final ExecutionEvent event;
}
