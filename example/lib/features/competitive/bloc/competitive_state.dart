import '../models/problem_model.dart';
import '../models/test_case_model.dart';

class CompetitiveState {
  const CompetitiveState({
    required this.activeProblem,
    required this.testCases,
    this.isRunning = false,
  });

  final ProblemModel activeProblem;
  final List<TestCase> testCases;
  final bool isRunning;

  int get passedCount => testCases.where((t) => t.isPassed).length;

  CompetitiveState copyWith({
    ProblemModel? activeProblem,
    List<TestCase>? testCases,
    bool? isRunning,
  }) {
    return CompetitiveState(
      activeProblem: activeProblem ?? this.activeProblem,
      testCases: testCases ?? this.testCases,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
