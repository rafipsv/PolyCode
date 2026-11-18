import 'package:flutter_bloc/flutter_bloc.dart';
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
  LayoutBloc({WorkspaceLayout initialLayout = WorkspaceLayout.ide})
      : super(LayoutState(activeLayout: initialLayout)) {
    on<SwitchLayout>((event, emit) {
      emit(state.copyWith(activeLayout: event.layout));
    });
    on<ToggleSidebar>((event, emit) {
      emit(state.copyWith(isSidebarOpen: !state.isSidebarOpen));
    });
    on<ToggleBottomPanel>((event, emit) {
      emit(state.copyWith(isBottomPanelOpen: !state.isBottomPanelOpen));
    });
    on<SetReadOnlyMode>((event, emit) {
      emit(state.copyWith(isReadOnly: event.isReadOnly));
    });
    on<ChangeEditorFontSize>((event, emit) {
      final updated = (state.fontSize + event.delta).clamp(10.0, 24.0);
      emit(state.copyWith(fontSize: updated));
    });
  }
}
