import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import 'ide_workspace_event.dart';
import 'ide_workspace_state.dart';

export 'ide_workspace_event.dart';
export 'ide_workspace_state.dart';

class IdeWorkspaceBloc extends Bloc<IdeEvent, IdeState> {
  IdeWorkspaceBloc({PolyLanguage initialLanguage = PolyLanguage.python})
      : super(IdeState.defaultState(initialLanguage)) {
    on<CreateFileRequested>((event, emit) {
      final updated = Map<String, SourceFile>.from(state.files);
      updated[event.fileName] = SourceFile(
        name: event.fileName,
        content: event.content,
      );
      final tabs = List<String>.from(state.openTabs);
      if (!tabs.contains(event.fileName)) tabs.add(event.fileName);
      emit(state.copyWith(
        files: updated,
        activeFileName: event.fileName,
        openTabs: tabs,
      ));
    });

    on<DeleteFileRequested>((event, emit) {
      if (state.files.length <= 1) return; // Keep at least one file
      final updated = Map<String, SourceFile>.from(state.files)
        ..remove(event.fileName);
      final tabs = List<String>.from(state.openTabs)..remove(event.fileName);
      final nextActive = tabs.isNotEmpty
          ? tabs.last
          : (updated.keys.isNotEmpty ? updated.keys.first : '');
      emit(state.copyWith(
        files: updated,
        openTabs: tabs.isEmpty && nextActive.isNotEmpty ? [nextActive] : tabs,
        activeFileName: nextActive,
      ));
    });

    on<SelectFileRequested>((event, emit) {
      if (!state.files.containsKey(event.fileName)) return;
      final tabs = List<String>.from(state.openTabs);
      if (!tabs.contains(event.fileName)) tabs.add(event.fileName);
      emit(state.copyWith(activeFileName: event.fileName, openTabs: tabs));
    });

    on<CloseTabRequested>((event, emit) {
      final tabs = List<String>.from(state.openTabs)..remove(event.fileName);
      final nextActive = state.activeFileName == event.fileName
          ? (tabs.isNotEmpty ? tabs.last : (state.files.keys.firstOrNull ?? ''))
          : state.activeFileName;
      emit(state.copyWith(openTabs: tabs, activeFileName: nextActive));
    });

    on<ToggleSearchRequested>((event, emit) {
      emit(state.copyWith(isSearchOpen: !state.isSearchOpen));
    });

    on<SearchQueryChanged>((event, emit) {
      emit(state.copyWith(searchQuery: event.query));
    });

    on<UpdateFileContentRequested>((event, emit) {
      final file = state.files[event.fileName];
      if (file == null) return;
      final updated = Map<String, SourceFile>.from(state.files);
      updated[event.fileName] = file.copyWith(content: event.content);
      emit(state.copyWith(files: updated));
    });

    on<LoadDemoProjectRequested>((event, emit) {
      emit(IdeState.defaultState(event.language));
    });
  }
}
