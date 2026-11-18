import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/preferences/preferences_storage.dart';
import '../../../core/theme/polycode_theme.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

class ToggleThemeRequested extends ThemeEvent {
  const ToggleThemeRequested();
}

class SetThemeModeRequested extends ThemeEvent {
  const SetThemeModeRequested(this.mode);
  final ThemeMode mode;
}

class SetThemePresetRequested extends ThemeEvent {
  const SetThemePresetRequested(this.preset);
  final PolyCodeThemePreset preset;
}

class LoadThemePreferencesRequested extends ThemeEvent {
  const LoadThemePreferencesRequested();
}

class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.dark,
    this.preset = PolyCodeThemePreset.dark,
    this.isLoaded = false,
  });

  final ThemeMode mode;
  final PolyCodeThemePreset preset;
  final bool isLoaded;

  bool get isDark => mode == ThemeMode.dark;
  bool get isHighContrast => preset == PolyCodeThemePreset.highContrast;

  ThemeData get darkTheme => isHighContrast
      ? PolyCodeTheme.highContrastTheme
      : PolyCodeTheme.darkTheme;

  ThemeData get lightTheme => PolyCodeTheme.lightTheme;

  ThemeState copyWith({
    ThemeMode? mode,
    PolyCodeThemePreset? preset,
    bool? isLoaded,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      preset: preset ?? this.preset,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({
    ThemeMode initialMode = ThemeMode.dark,
    PolyCodeThemePreset initialPreset = PolyCodeThemePreset.dark,
    PreferencesStorage? storage,
  })  : _storage = storage,
        super(ThemeState(mode: initialMode, preset: initialPreset)) {
    on<ToggleThemeRequested>(_onToggle);
    on<SetThemeModeRequested>(_onSetMode);
    on<SetThemePresetRequested>(_onSetPreset);
    on<LoadThemePreferencesRequested>(_onLoad);

    if (_storage != null) {
      add(const LoadThemePreferencesRequested());
    }
  }

  final PreferencesStorage? _storage;

  Future<void> _onToggle(
      ToggleThemeRequested event, Emitter<ThemeState> emit) async {
    final nextMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(mode: nextMode));
    await _storage?.setString('polycode_theme_mode', nextMode.name);
  }

  Future<void> _onSetMode(
      SetThemeModeRequested event, Emitter<ThemeState> emit) async {
    emit(state.copyWith(mode: event.mode));
    await _storage?.setString('polycode_theme_mode', event.mode.name);
  }

  Future<void> _onSetPreset(
      SetThemePresetRequested event, Emitter<ThemeState> emit) async {
    final targetMode = event.preset == PolyCodeThemePreset.light
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(state.copyWith(preset: event.preset, mode: targetMode));
    await _storage?.setString('polycode_theme_preset', event.preset.name);
    await _storage?.setString('polycode_theme_mode', targetMode.name);
  }

  Future<void> _onLoad(
      LoadThemePreferencesRequested event, Emitter<ThemeState> emit) async {
    final storage = _storage;
    if (storage == null) return;
    final savedMode = await storage.getString('polycode_theme_mode');
    final savedPreset = await storage.getString('polycode_theme_preset');

    ThemeMode mode = state.mode;
    if (savedMode != null) {
      mode = ThemeMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => state.mode,
      );
    }

    PolyCodeThemePreset preset = state.preset;
    if (savedPreset != null) {
      preset = PolyCodeThemePreset.values.firstWhere(
        (p) => p.name == savedPreset,
        orElse: () => state.preset,
      );
    }

    emit(state.copyWith(mode: mode, preset: preset, isLoaded: true));
  }
}
