import 'package:flutter/material.dart';

/// Available built-in theme presets.
enum PolyCodeThemePreset {
  dark('Dark (Default)'),
  light('Light'),
  highContrast('High Contrast');

  const PolyCodeThemePreset(this.displayName);
  final String displayName;
}

/// Centralized design tokens for PolyCode styling across all layouts and widgets.
class PolyCodeThemeTokens extends ThemeExtension<PolyCodeThemeTokens> {
  const PolyCodeThemeTokens({
    required this.appBackground,
    required this.panelBackground,
    required this.panelHeader,
    required this.elevatedPanel,
    required this.editorBackground,
    required this.terminalBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.border,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.selection,
    required this.lineNumber,
    required this.cursor,
    required this.syntaxKeyword,
    required this.syntaxString,
    required this.syntaxComment,
    required this.syntaxNumber,
    required this.syntaxFunction,
    required this.syntaxType,
    required this.terminalForeground,
    required this.terminalPrompt,
  });

  final Color appBackground;
  final Color panelBackground;
  final Color panelHeader;
  final Color elevatedPanel;
  final Color editorBackground;
  final Color terminalBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color border;
  final Color accent;
  final Color success;
  final Color warning;
  final Color error;
  final Color selection;
  final Color lineNumber;
  final Color cursor;
  final Color syntaxKeyword;
  final Color syntaxString;
  final Color syntaxComment;
  final Color syntaxNumber;
  final Color syntaxFunction;
  final Color syntaxType;
  final Color terminalForeground;
  final Color terminalPrompt;

  // Dark Palette
  static const Color darkAppBackground = Color(0xFF121417);
  static const Color darkPanelBackground = Color(0xFF1E2228);
  static const Color darkPanelHeader = Color(0xFF262C34);
  static const Color darkElevatedPanel = Color(0xFF2A313A);
  static const Color darkEditorBackground = Color(0xFF181B20);
  static const Color darkTerminalBackground = Color(0xFF0F1115);
  static const Color darkPrimaryText = Color(0xFFE6EDF3);
  static const Color darkSecondaryText = Color(0xFF8B949E);
  static const Color darkMutedText = Color(0xFF6E7681);
  static const Color darkBorder = Color(0xFF333B46);
  static const Color darkAccent = Color(0xFF2EA043);
  static const Color darkSuccess = Color(0xFF3FB950);
  static const Color darkWarning = Color(0xFFD29922);
  static const Color darkError = Color(0xFFF85149);
  static const Color darkSelection = Color(0xFF264F78);
  static const Color darkLineNumber = Color(0xFF6E7681);
  static const Color darkCursor = Color(0xFF58A6FF);
  static const Color darkSyntaxKeyword = Color(0xFFFF7B72);
  static const Color darkSyntaxString = Color(0xFFA5D6FF);
  static const Color darkSyntaxComment = Color(0xFF8B949E);
  static const Color darkSyntaxNumber = Color(0xFF79C0FF);
  static const Color darkSyntaxFunction = Color(0xFFD2A8FF);
  static const Color darkSyntaxType = Color(0xFFFFA657);
  static const Color darkTerminalForeground = Color(0xFFE6EDF3);
  static const Color darkTerminalPrompt = Color(0xFF3FB950);

  // Light Palette
  static const Color lightAppBackground = Color(0xFFF6F8FA);
  static const Color lightPanelBackground = Color(0xFFFFFFFF);
  static const Color lightPanelHeader = Color(0xFFEAEEF2);
  static const Color lightElevatedPanel = Color(0xFFF0F2F5);
  static const Color lightEditorBackground = Color(0xFFFFFFFF);
  static const Color lightTerminalBackground = Color(0xFFF3F4F6);
  static const Color lightPrimaryText = Color(0xFF1F2328);
  static const Color lightSecondaryText = Color(0xFF656D76);
  static const Color lightMutedText = Color(0xFF8C959F);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightAccent = Color(0xFF1F883D);
  static const Color lightSuccess = Color(0xFF1A7F37);
  static const Color lightWarning = Color(0xFF9A6700);
  static const Color lightError = Color(0xFFCF222E);
  static const Color lightSelection = Color(0xFFB4D5FE);
  static const Color lightLineNumber = Color(0xFF8C959F);
  static const Color lightCursor = Color(0xFF0969DA);
  static const Color lightSyntaxKeyword = Color(0xFFCF222E);
  static const Color lightSyntaxString = Color(0xFF0A3069);
  static const Color lightSyntaxComment = Color(0xFF6E7781);
  static const Color lightSyntaxNumber = Color(0xFF0550AE);
  static const Color lightSyntaxFunction = Color(0xFF8250DF);
  static const Color lightSyntaxType = Color(0xFF953800);
  static const Color lightTerminalForeground = Color(0xFF1F2328);
  static const Color lightTerminalPrompt = Color(0xFF1A7F37);

  // High Contrast Palette
  static const Color hcAppBackground = Color(0xFF000000);
  static const Color hcPanelBackground = Color(0xFF0A0A0A);
  static const Color hcPanelHeader = Color(0xFF1A1A1A);
  static const Color hcElevatedPanel = Color(0xFF222222);
  static const Color hcEditorBackground = Color(0xFF000000);
  static const Color hcTerminalBackground = Color(0xFF000000);
  static const Color hcPrimaryText = Color(0xFFFFFFFF);
  static const Color hcSecondaryText = Color(0xFFE0E0E0);
  static const Color hcMutedText = Color(0xFFB0B0B0);
  static const Color hcBorder = Color(0xFFFFFFFF);
  static const Color hcAccent = Color(0xFF00FF66);
  static const Color hcSuccess = Color(0xFF00FF66);
  static const Color hcWarning = Color(0xFFFFDD00);
  static const Color hcError = Color(0xFFFF3333);
  static const Color hcSelection = Color(0xFF0055FF);
  static const Color hcLineNumber = Color(0xFFCCCCCC);
  static const Color hcCursor = Color(0xFF00FFFF);
  static const Color hcSyntaxKeyword = Color(0xFFFF5555);
  static const Color hcSyntaxString = Color(0xFF55FFFF);
  static const Color hcSyntaxComment = Color(0xFFAAAAAA);
  static const Color hcSyntaxNumber = Color(0xFFFFFF55);
  static const Color hcSyntaxFunction = Color(0xFFFF55FF);
  static const Color hcSyntaxType = Color(0xFFFFAA00);
  static const Color hcTerminalForeground = Color(0xFFFFFFFF);
  static const Color hcTerminalPrompt = Color(0xFF00FF66);

  /// Default dark theme design tokens.
  static const dark = PolyCodeThemeTokens(
    appBackground: darkAppBackground,
    panelBackground: darkPanelBackground,
    panelHeader: darkPanelHeader,
    elevatedPanel: darkElevatedPanel,
    editorBackground: darkEditorBackground,
    terminalBackground: darkTerminalBackground,
    primaryText: darkPrimaryText,
    secondaryText: darkSecondaryText,
    mutedText: darkMutedText,
    border: darkBorder,
    accent: darkAccent,
    success: darkSuccess,
    warning: darkWarning,
    error: darkError,
    selection: darkSelection,
    lineNumber: darkLineNumber,
    cursor: darkCursor,
    syntaxKeyword: darkSyntaxKeyword,
    syntaxString: darkSyntaxString,
    syntaxComment: darkSyntaxComment,
    syntaxNumber: darkSyntaxNumber,
    syntaxFunction: darkSyntaxFunction,
    syntaxType: darkSyntaxType,
    terminalForeground: darkTerminalForeground,
    terminalPrompt: darkTerminalPrompt,
  );

  /// Clean light theme design tokens.
  static const light = PolyCodeThemeTokens(
    appBackground: lightAppBackground,
    panelBackground: lightPanelBackground,
    panelHeader: lightPanelHeader,
    elevatedPanel: lightElevatedPanel,
    editorBackground: lightEditorBackground,
    terminalBackground: lightTerminalBackground,
    primaryText: lightPrimaryText,
    secondaryText: lightSecondaryText,
    mutedText: lightMutedText,
    border: lightBorder,
    accent: lightAccent,
    success: lightSuccess,
    warning: lightWarning,
    error: lightError,
    selection: lightSelection,
    lineNumber: lightLineNumber,
    cursor: lightCursor,
    syntaxKeyword: lightSyntaxKeyword,
    syntaxString: lightSyntaxString,
    syntaxComment: lightSyntaxComment,
    syntaxNumber: lightSyntaxNumber,
    syntaxFunction: lightSyntaxFunction,
    syntaxType: lightSyntaxType,
    terminalForeground: lightTerminalForeground,
    terminalPrompt: lightTerminalPrompt,
  );

  /// High contrast dark theme design tokens for enhanced visibility and WCAG compliance.
  static const highContrast = PolyCodeThemeTokens(
    appBackground: hcAppBackground,
    panelBackground: hcPanelBackground,
    panelHeader: hcPanelHeader,
    elevatedPanel: hcElevatedPanel,
    editorBackground: hcEditorBackground,
    terminalBackground: hcTerminalBackground,
    primaryText: hcPrimaryText,
    secondaryText: hcSecondaryText,
    mutedText: hcMutedText,
    border: hcBorder,
    accent: hcAccent,
    success: hcSuccess,
    warning: hcWarning,
    error: hcError,
    selection: hcSelection,
    lineNumber: hcLineNumber,
    cursor: hcCursor,
    syntaxKeyword: hcSyntaxKeyword,
    syntaxString: hcSyntaxString,
    syntaxComment: hcSyntaxComment,
    syntaxNumber: hcSyntaxNumber,
    syntaxFunction: hcSyntaxFunction,
    syntaxType: hcSyntaxType,
    terminalForeground: hcTerminalForeground,
    terminalPrompt: hcTerminalPrompt,
  );

  @override
  PolyCodeThemeTokens copyWith({
    Color? appBackground,
    Color? panelBackground,
    Color? panelHeader,
    Color? elevatedPanel,
    Color? editorBackground,
    Color? terminalBackground,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? border,
    Color? accent,
    Color? success,
    Color? warning,
    Color? error,
    Color? selection,
    Color? lineNumber,
    Color? cursor,
    Color? syntaxKeyword,
    Color? syntaxString,
    Color? syntaxComment,
    Color? syntaxNumber,
    Color? syntaxFunction,
    Color? syntaxType,
    Color? terminalForeground,
    Color? terminalPrompt,
  }) {
    return PolyCodeThemeTokens(
      appBackground: appBackground ?? this.appBackground,
      panelBackground: panelBackground ?? this.panelBackground,
      panelHeader: panelHeader ?? this.panelHeader,
      elevatedPanel: elevatedPanel ?? this.elevatedPanel,
      editorBackground: editorBackground ?? this.editorBackground,
      terminalBackground: terminalBackground ?? this.terminalBackground,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      selection: selection ?? this.selection,
      lineNumber: lineNumber ?? this.lineNumber,
      cursor: cursor ?? this.cursor,
      syntaxKeyword: syntaxKeyword ?? this.syntaxKeyword,
      syntaxString: syntaxString ?? this.syntaxString,
      syntaxComment: syntaxComment ?? this.syntaxComment,
      syntaxNumber: syntaxNumber ?? this.syntaxNumber,
      syntaxFunction: syntaxFunction ?? this.syntaxFunction,
      syntaxType: syntaxType ?? this.syntaxType,
      terminalForeground: terminalForeground ?? this.terminalForeground,
      terminalPrompt: terminalPrompt ?? this.terminalPrompt,
    );
  }

  @override
  ThemeExtension<PolyCodeThemeTokens> lerp(
    covariant ThemeExtension<PolyCodeThemeTokens>? other,
    double t,
  ) {
    if (other is! PolyCodeThemeTokens) return this;

    return PolyCodeThemeTokens(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      panelHeader: Color.lerp(panelHeader, other.panelHeader, t)!,
      elevatedPanel: Color.lerp(elevatedPanel, other.elevatedPanel, t)!,
      editorBackground:
          Color.lerp(editorBackground, other.editorBackground, t)!,
      terminalBackground:
          Color.lerp(terminalBackground, other.terminalBackground, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      selection: Color.lerp(selection, other.selection, t)!,
      lineNumber: Color.lerp(lineNumber, other.lineNumber, t)!,
      cursor: Color.lerp(cursor, other.cursor, t)!,
      syntaxKeyword: Color.lerp(syntaxKeyword, other.syntaxKeyword, t)!,
      syntaxString: Color.lerp(syntaxString, other.syntaxString, t)!,
      syntaxComment: Color.lerp(syntaxComment, other.syntaxComment, t)!,
      syntaxNumber: Color.lerp(syntaxNumber, other.syntaxNumber, t)!,
      syntaxFunction: Color.lerp(syntaxFunction, other.syntaxFunction, t)!,
      syntaxType: Color.lerp(syntaxType, other.syntaxType, t)!,
      terminalForeground:
          Color.lerp(terminalForeground, other.terminalForeground, t)!,
      terminalPrompt: Color.lerp(terminalPrompt, other.terminalPrompt, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] to access [PolyCodeThemeTokens] easily.
extension PolyCodeThemeContextExtension on BuildContext {
  PolyCodeThemeTokens get polyTheme {
    return Theme.of(this).extension<PolyCodeThemeTokens>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? PolyCodeThemeTokens.dark
            : PolyCodeThemeTokens.light);
  }
}
