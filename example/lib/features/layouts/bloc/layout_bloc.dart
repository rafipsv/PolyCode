import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/preferences/preferences_storage.dart';
import '../models/workspace_layout.dart';

sealed class LayoutEvent {
  const LayoutEvent();
}

class SwitchLayout extends LayoutEvent {
  const SwitchLayout(this.layout);
  final WorkspaceLayout layout;
}

class ToggleSidebar extends LayoutEvent {
  const ToggleSidebar();
}

class ToggleBottomPanel extends LayoutEvent {
  const ToggleBottomPanel();
}

class SetReadOnlyMode extends LayoutEvent {
  const SetReadOnlyMode(this.isReadOnly);
  final bool isReadOnly;
}

class ChangeEditorFontSize extends LayoutEvent {
  const ChangeEditorFontSize(this.delta);
  final double delta;
}

class LoadLayoutPreferencesRequested extends LayoutEvent {
  const LoadLayoutPreferencesRequested();
}

class LayoutState {
  const LayoutState({
    this.activeLayout = WorkspaceLayout.ide,
    this.isSidebarOpen = true,
    this.isBottomPanelOpen = true,
    this.isReadOnly = false,
    this.fontSize = 13.0,
  });

  final WorkspaceLayout activeLayout;
  final bool isSidebarOpen;
  final bool isBottomPanelOpen;
  final bool isReadOnly;
  final double fontSize;

  LayoutState copyWith({
    WorkspaceLayout? activeLayout,
    bool? isSidebarOpen,
    bool? isBottomPanelOpen,
    bool? isReadOnly,
    double? fontSize,
  }) {
    return LayoutState(
      activeLayout: activeLayout ?? this.activeLayout,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      isBottomPanelOpen: isBottomPanelOpen ?? this.isBottomPanelOpen,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class LayoutBloc extends Bloc<LayoutEvent, LayoutState> {
  LayoutBloc({
    WorkspaceLayout initialLayout = WorkspaceLayout.ide,
    PreferencesStorage? storage,
  })  : _storage = storage,
        super(LayoutState(activeLayout: initialLayout)) {
    on<SwitchLayout>(_onSwitchLayout);
    on<ToggleSidebar>(_onToggleSidebar);
    on<ToggleBottomPanel>(_onToggleBottomPanel);
    on<SetReadOnlyMode>(_onSetReadOnly);
    on<ChangeEditorFontSize>(_onChangeFontSize);
    on<LoadLayoutPreferencesRequested>(_onLoadPreferences);

    if (_storage != null) {
      add(const LoadLayoutPreferencesRequested());
    }
  }

  final PreferencesStorage? _storage;

  Future<void> _onSwitchLayout(
      SwitchLayout event, Emitter<LayoutState> emit) async {
    emit(state.copyWith(activeLayout: event.layout));
    await _storage?.setString('polycode_layout', event.layout.name);
  }

  Future<void> _onToggleSidebar(
      ToggleSidebar event, Emitter<LayoutState> emit) async {
    final next = !state.isSidebarOpen;
    emit(state.copyWith(isSidebarOpen: next));
    await _storage?.setBool('polycode_sidebar_open', next);
  }

  Future<void> _onToggleBottomPanel(
      ToggleBottomPanel event, Emitter<LayoutState> emit) async {
    final next = !state.isBottomPanelOpen;
    emit(state.copyWith(isBottomPanelOpen: next));
    await _storage?.setBool('polycode_bottom_panel_open', next);
  }

  Future<void> _onSetReadOnly(
      SetReadOnlyMode event, Emitter<LayoutState> emit) async {
    emit(state.copyWith(isReadOnly: event.isReadOnly));
    await _storage?.setBool('polycode_read_only', event.isReadOnly);
  }

  Future<void> _onChangeFontSize(
      ChangeEditorFontSize event, Emitter<LayoutState> emit) async {
    final updated = (state.fontSize + event.delta).clamp(10.0, 24.0);
    emit(state.copyWith(fontSize: updated));
    await _storage?.setDouble('polycode_font_size', updated);
  }

  Future<void> _onLoadPreferences(
      LoadLayoutPreferencesRequested event, Emitter<LayoutState> emit) async {
    final storage = _storage;
    if (storage == null) return;
    final savedLayout = await storage.getString('polycode_layout');
    final savedSidebar = await storage.getBool('polycode_sidebar_open');
    final savedBottom = await storage.getBool('polycode_bottom_panel_open');
    final savedReadOnly = await storage.getBool('polycode_read_only');
    final savedFontSize = await storage.getDouble('polycode_font_size');

    WorkspaceLayout layout = state.activeLayout;
    if (savedLayout != null) {
      layout = WorkspaceLayout.values.firstWhere(
        (l) => l.name == savedLayout,
        orElse: () => state.activeLayout,
      );
    }

    emit(state.copyWith(
      activeLayout: layout,
      isSidebarOpen: savedSidebar ?? state.isSidebarOpen,
      isBottomPanelOpen: savedBottom ?? state.isBottomPanelOpen,
      isReadOnly: savedReadOnly ?? state.isReadOnly,
      fontSize: savedFontSize ?? state.fontSize,
    ));
  }
}
