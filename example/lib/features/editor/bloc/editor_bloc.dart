import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';

sealed class EditorEvent {
  const EditorEvent();
}

class SourceChanged extends EditorEvent {
  const SourceChanged(this.newSource);
  final String newSource;
}

class LanguageChanged extends EditorEvent {
  const LanguageChanged(this.newLanguage);
  final PolyLanguage newLanguage;
}

class ResetTemplateRequested extends EditorEvent {
  const ResetTemplateRequested();
}

class EditorState {
  const EditorState({
    required this.language,
    required this.source,
    this.isDirty = false,
  });

  final PolyLanguage language;
  final String source;
  final bool isDirty;

  static const Map<PolyLanguage, String> defaultTemplates = {
    PolyLanguage.javascript: '''// PolyCode JavaScript Runner
console.log("Hello from PolyCode Web JavaScript!");
const numbers = [1, 2, 3, 4, 5];
const doubled = numbers.map(x => x * 2);
console.log("Doubled numbers:", doubled);
''',
    PolyLanguage.python: '''# PolyCode Python Runner
def greet(name):
    return f"Hello, {name}! Welcome to PolyCode."

print(greet("Developer"))
total = sum([x**2 for x in range(1, 6)])
print("Sum of squares:", total)
''',
    PolyLanguage.c: '''#include <stdio.h>

int main() {
    printf("Hello from PolyCode C!\\n");
    int a = 10, b = 20;
    printf("Result: %d + %d = %d\\n", a, b, a + b);
    return 0;
}
''',
    PolyLanguage.cpp: '''#include <iostream>
#include <vector>
#include <numeric>

int main() {
    std::cout << "Hello from PolyCode C++!" << std::endl;
    std::vector<int> nums = {1, 2, 3, 4, 5};
    int total = std::accumulate(nums.begin(), nums.end(), 0);
    std::cout << "Sum of vector elements: " << total << std::endl;
    return 0;
}
''',
  };

  EditorState copyWith({
    PolyLanguage? language,
    String? source,
    bool? isDirty,
  }) {
    return EditorState(
      language: language ?? this.language,
      source: source ?? this.source,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  EditorBloc({PolyLanguage initialLanguage = PolyLanguage.python})
      : super(
          EditorState(
            language: initialLanguage,
            source: EditorState.defaultTemplates[initialLanguage] ?? '',
          ),
        ) {
    on<SourceChanged>((event, emit) {
      emit(state.copyWith(source: event.newSource, isDirty: true));
    });

    on<LanguageChanged>((event, emit) {
      final template = EditorState.defaultTemplates[event.newLanguage] ??
          '// Write ${event.newLanguage.displayName} code here...\n';
      emit(
        state.copyWith(
          language: event.newLanguage,
          source: template,
          isDirty: false,
        ),
      );
    });

    on<ResetTemplateRequested>((event, emit) {
      final template = EditorState.defaultTemplates[state.language] ?? '';
      emit(state.copyWith(source: template, isDirty: false));
    });
  }
}
