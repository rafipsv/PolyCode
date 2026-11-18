import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import 'editor_templates.dart';

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

  static const Map<PolyLanguage, String> defaultTemplates =
      EditorTemplates.defaults;

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
            source: EditorTemplates.defaults[initialLanguage] ?? '',
          ),
        ) {
    on<SourceChanged>((event, emit) {
      emit(state.copyWith(source: event.newSource, isDirty: true));
    });

    on<LanguageChanged>((event, emit) {
      final template = EditorTemplates.defaults[event.newLanguage] ??
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
      final template = EditorTemplates.defaults[state.language] ?? '';
      emit(state.copyWith(source: template, isDirty: false));
    });
  }
}
