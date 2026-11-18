import 'package:flutter/material.dart';
import 'polycode_theme_tokens.dart';

export 'polycode_theme_tokens.dart';

/// Central design tokens, color palettes, and theme configurations for the PolyCode playground.
class PolyCodeTheme {
  PolyCodeTheme._();

  // Backward-compatible static constants
  static const Color darkBackground = PolyCodeThemeTokens.darkAppBackground;
  static const Color darkSurface = PolyCodeThemeTokens.darkPanelBackground;
  static const Color darkPanelHeader = PolyCodeThemeTokens.darkPanelHeader;
  static const Color darkBorder = PolyCodeThemeTokens.darkBorder;
  static const Color darkEditorBackground =
      PolyCodeThemeTokens.darkEditorBackground;
  static const Color darkTerminalBackground =
      PolyCodeThemeTokens.darkTerminalBackground;
  static const Color darkTextPrimary = PolyCodeThemeTokens.darkPrimaryText;
  static const Color darkTextSecondary = PolyCodeThemeTokens.darkSecondaryText;

  static const Color lightBackground = PolyCodeThemeTokens.lightAppBackground;
  static const Color lightSurface = PolyCodeThemeTokens.lightPanelBackground;
  static const Color lightPanelHeader = PolyCodeThemeTokens.lightPanelHeader;
  static const Color lightBorder = PolyCodeThemeTokens.lightBorder;
  static const Color lightEditorBackground =
      PolyCodeThemeTokens.lightEditorBackground;
  static const Color lightTerminalBackground =
      PolyCodeThemeTokens.lightTerminalBackground;
  static const Color lightTextPrimary = PolyCodeThemeTokens.lightPrimaryText;
  static const Color lightTextSecondary =
      PolyCodeThemeTokens.lightSecondaryText;

  static const Color accentColor = PolyCodeThemeTokens.darkAccent;
  static const Color errorColor = PolyCodeThemeTokens.darkError;
  static const Color warningColor = PolyCodeThemeTokens.darkWarning;
  static const Color infoColor = Color(0xFF58A6FF);

  /// Resolves ThemeData from a specific preset.
  static ThemeData themeFromPreset(PolyCodeThemePreset preset) {
    switch (preset) {
      case PolyCodeThemePreset.dark:
        return darkTheme;
      case PolyCodeThemePreset.light:
        return lightTheme;
      case PolyCodeThemePreset.highContrast:
        return highContrastTheme;
    }
  }

  /// Dark theme configuration.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PolyCodeThemeTokens.darkAppBackground,
      cardColor: PolyCodeThemeTokens.darkPanelBackground,
      dividerColor: PolyCodeThemeTokens.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: PolyCodeThemeTokens.darkAccent,
        surface: PolyCodeThemeTokens.darkPanelBackground,
        onSurface: PolyCodeThemeTokens.darkPrimaryText,
        outline: PolyCodeThemeTokens.darkBorder,
        error: PolyCodeThemeTokens.darkError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PolyCodeThemeTokens.darkPanelHeader,
        foregroundColor: PolyCodeThemeTokens.darkPrimaryText,
        elevation: 0,
      ),
      extensions: const [PolyCodeThemeTokens.dark],
    );
  }

  /// Light theme configuration.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PolyCodeThemeTokens.lightAppBackground,
      cardColor: PolyCodeThemeTokens.lightPanelBackground,
      dividerColor: PolyCodeThemeTokens.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: PolyCodeThemeTokens.lightAccent,
        surface: PolyCodeThemeTokens.lightPanelBackground,
        onSurface: PolyCodeThemeTokens.lightPrimaryText,
        outline: PolyCodeThemeTokens.lightBorder,
        error: PolyCodeThemeTokens.lightError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PolyCodeThemeTokens.lightPanelHeader,
        foregroundColor: PolyCodeThemeTokens.lightPrimaryText,
        elevation: 0,
      ),
      extensions: const [PolyCodeThemeTokens.light],
    );
  }

  /// High contrast dark theme configuration for accessibility.
  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PolyCodeThemeTokens.hcAppBackground,
      cardColor: PolyCodeThemeTokens.hcPanelBackground,
      dividerColor: PolyCodeThemeTokens.hcBorder,
      colorScheme: const ColorScheme.dark(
        primary: PolyCodeThemeTokens.hcAccent,
        surface: PolyCodeThemeTokens.hcPanelBackground,
        onSurface: PolyCodeThemeTokens.hcPrimaryText,
        outline: PolyCodeThemeTokens.hcBorder,
        error: PolyCodeThemeTokens.hcError,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PolyCodeThemeTokens.hcPanelHeader,
        foregroundColor: PolyCodeThemeTokens.hcPrimaryText,
        elevation: 0,
      ),
      extensions: const [PolyCodeThemeTokens.highContrast],
    );
  }
}
