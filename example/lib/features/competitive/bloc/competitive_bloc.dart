import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import '../models/problem_model.dart';
import '../models/test_case_model.dart';
import 'competitive_event.dart';
import 'competitive_state.dart';

export 'competitive_event.dart';
export 'competitive_state.dart';

class CompetitiveBloc extends Bloc<CompetitiveEvent, CompetitiveState> {
  CompetitiveBloc({required this.polycode})
      : super(
          CompetitiveState(
            activeProblem: ProblemModel.sampleProblems.first,
            testCases: List.of(ProblemModel.sampleProblems.first.testCases),
          ),
        ) {
    on<SelectProblemRequested>((event, emit) {
      emit(state.copyWith(
        activeProblem: event.problem,
        testCases: List.of(event.problem.testCases),
        isRunning: false,
      ));
    });

    on<AddTestCaseRequested>((event, emit) {
      final newCase = TestCase(
        id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
        input: event.input,
        expectedOutput: event.expectedOutput,
      );
      emit(state.copyWith(testCases: [...state.testCases, newCase]));
    });

    on<RemoveTestCaseRequested>((event, emit) {
      emit(state.copyWith(
        testCases: state.testCases.where((tc) => tc.id != event.id).toList(),
      ));
    });

    on<RunAllTestCasesRequested>(_onRunAllTestCases);
  }

  final PolyCode polycode;

  Future<void> _onRunAllTestCases(
    RunAllTestCasesRequested event,
    Emitter<CompetitiveState> emit,
  ) async {
    if (state.isRunning) return;
    emit(state.copyWith(isRunning: true));

    final updated = List<TestCase>.from(state.testCases);
    for (int i = 0; i < updated.length; i++) {
      final current = updated[i];
      updated[i] = current.copyWith(verdict: TestCaseVerdict.running);
      emit(state.copyWith(testCases: List.of(updated)));

      final sw = Stopwatch()..start();
      try {
        final result = await polycode.execute(
          ExecutionRequest(
            language: event.language,
            source: event.source,
            stdin: current.input,
          ),
        );
        sw.stop();
        final actual = result.stdout.trim();
        final expected = current.expectedOutput.trim();
        final isMatch = actual == expected;
        final isError = result.exitCode != 0 || result.stderr.isNotEmpty;

        updated[i] = current.copyWith(
          actualOutput: actual,
          executionTime: sw.elapsed,
          verdict: isError
              ? TestCaseVerdict.runtimeError
              : (isMatch
                  ? TestCaseVerdict.accepted
                  : TestCaseVerdict.wrongAnswer),
          errorMessage: isError ? result.stderr : null,
        );
      } catch (e) {
        sw.stop();
        updated[i] = current.copyWith(
          actualOutput: '',
          executionTime: sw.elapsed,
          verdict: TestCaseVerdict.runtimeError,
          errorMessage: e.toString(),
        );
      }
      emit(state.copyWith(testCases: List.of(updated)));
    }

    emit(state.copyWith(isRunning: false));
  }
}
