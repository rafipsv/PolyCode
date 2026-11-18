import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import '../../../core/preferences/preferences_storage.dart';
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

class LoadEditorPreferencesRequested extends EditorEvent {
  const LoadEditorPreferencesRequested();
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
  EditorBloc({
    PolyLanguage initialLanguage = PolyLanguage.python,
    PreferencesStorage? storage,
  })  : _storage = storage,
        super(
          EditorState(
            language: initialLanguage,
            source: EditorTemplates.defaults[initialLanguage] ?? '',
          ),
        ) {
    on<SourceChanged>((event, emit) {
      emit(state.copyWith(source: event.newSource, isDirty: true));
    });

    on<LanguageChanged>(_onLanguageChanged);
    on<ResetTemplateRequested>(_onResetTemplate);
    on<LoadEditorPreferencesRequested>(_onLoadPreferences);

    if (_storage != null) {
      add(const LoadEditorPreferencesRequested());
    }
  }

  final PreferencesStorage? _storage;

  Future<void> _onLanguageChanged(
      LanguageChanged event, Emitter<EditorState> emit) async {
    final template = EditorTemplates.defaults[event.newLanguage] ??
        '// Write ${event.newLanguage.displayName} code here...\n';
    emit(
      state.copyWith(
        language: event.newLanguage,
        source: template,
        isDirty: false,
      ),
    );
    await _storage?.setString(
        'polycode_editor_language', event.newLanguage.name);
  }

  void _onResetTemplate(
      ResetTemplateRequested event, Emitter<EditorState> emit) {
    final template = EditorTemplates.defaults[state.language] ?? '';
    emit(state.copyWith(source: template, isDirty: false));
  }

  Future<void> _onLoadPreferences(
      LoadEditorPreferencesRequested event, Emitter<EditorState> emit) async {
    final storage = _storage;
    if (storage == null) return;
    final savedLang = await storage.getString('polycode_editor_language');
    if (savedLang != null) {
      final lang = PolyLanguage.values.firstWhere(
        (l) => l.name == savedLang,
        orElse: () => state.language,
      );
      if (lang != state.language && !state.isDirty) {
        emit(state.copyWith(
          language: lang,
          source: EditorTemplates.defaults[lang] ?? state.source,
        ));
      }
    }
  }
}
