import 'package:polycode/polycode.dart';
import '../models/problem_model.dart';

sealed class CompetitiveEvent {
  const CompetitiveEvent();
}

class SelectProblemRequested extends CompetitiveEvent {
  const SelectProblemRequested(this.problem);
  final ProblemModel problem;
}

class AddTestCaseRequested extends CompetitiveEvent {
  const AddTestCaseRequested({
    required this.input,
    required this.expectedOutput,
  });
  final String input;
  final String expectedOutput;
}

class RemoveTestCaseRequested extends CompetitiveEvent {
  const RemoveTestCaseRequested(this.id);
  final String id;
}

class RunAllTestCasesRequested extends CompetitiveEvent {
  const RunAllTestCasesRequested({
    required this.language,
    required this.source,
  });
  final PolyLanguage language;
  final String source;
}
