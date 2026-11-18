import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

class ToggleThemeRequested extends ThemeEvent {
  const ToggleThemeRequested();
}

class ThemeState {
  const ThemeState({this.mode = ThemeMode.dark});
  final ThemeMode mode;

  bool get isDark => mode == ThemeMode.dark;

  ThemeState copyWith({ThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({ThemeMode initialMode = ThemeMode.dark})
      : super(ThemeState(mode: initialMode)) {
    on<ToggleThemeRequested>((event, emit) {
      final nextMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
      emit(state.copyWith(mode: nextMode));
    });
  }
}
