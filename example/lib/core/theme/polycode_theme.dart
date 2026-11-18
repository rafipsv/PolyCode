import 'package:flutter/material.dart';

/// Central design tokens and color palettes for the PolyCode playground.
class PolyCodeTheme {
  PolyCodeTheme._();

  // Dark Theme Tokens
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF1E2228);
  static const Color darkPanelHeader = Color(0xFF262C34);
  static const Color darkBorder = Color(0xFF333B46);
  static const Color darkEditorBackground = Color(0xFF181B20);
  static const Color darkTerminalBackground = Color(0xFF0F1115);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);

  // Light Theme Tokens
  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPanelHeader = Color(0xFFEAEEF2);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightEditorBackground = Color(0xFFFFFFFF);
  static const Color lightTerminalBackground = Color(0xFFF3F4F6);
  static const Color lightTextPrimary = Color(0xFF1F2328);
  static const Color lightTextSecondary = Color(0xFF656D76);

  // Accents & State Colors
  static const Color accentColor = Color(0xFF2EA043); // Emerald run green
  static const Color errorColor = Color(0xFFF85149);
  static const Color warningColor = Color(0xFFD29922);
  static const Color infoColor = Color(0xFF58A6FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPanelHeader,
        foregroundColor: darkTextPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        outline: lightBorder,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPanelHeader,
        foregroundColor: lightTextPrimary,
        elevation: 0,
      ),
    );
  }
}
