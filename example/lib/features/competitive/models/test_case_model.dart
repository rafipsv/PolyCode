import 'package:flutter/foundation.dart';

enum TestCaseVerdict {
  notRun,
  running,
  accepted,
  wrongAnswer,
  runtimeError,
  timeLimitExceeded,
}

@immutable
class TestCase {
  const TestCase({
    required this.id,
    required this.input,
    required this.expectedOutput,
    this.actualOutput = '',
    this.verdict = TestCaseVerdict.notRun,
    this.executionTime = Duration.zero,
    this.errorMessage,
  });

  final String id;
  final String input;
  final String expectedOutput;
  final String actualOutput;
  final TestCaseVerdict verdict;
  final Duration executionTime;
  final String? errorMessage;

  bool get isPassed => verdict == TestCaseVerdict.accepted;

  TestCase copyWith({
    String? id,
    String? input,
    String? expectedOutput,
    String? actualOutput,
    TestCaseVerdict? verdict,
    Duration? executionTime,
    String? errorMessage,
  }) {
    return TestCase(
      id: id ?? this.id,
      input: input ?? this.input,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      actualOutput: actualOutput ?? this.actualOutput,
      verdict: verdict ?? this.verdict,
      executionTime: executionTime ?? this.executionTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
