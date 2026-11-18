import 'package:flutter/material.dart';
import 'package:polycode/polycode.dart';
import '../../../core/theme/polycode_theme_tokens.dart';

/// Lightweight syntax highlighting controller adhering to active theme tokens.
class SyntaxHighlighterEditingController extends TextEditingController {
  SyntaxHighlighterEditingController({
    super.text,
    required this.language,
    required this.tokens,
  });

  PolyLanguage language;
  PolyCodeThemeTokens tokens;

  void updateThemeAndLanguage(PolyLanguage newLang, PolyCodeThemeTokens newTokens) {
    language = newLang;
    tokens = newTokens;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final rawText = text;
    if (rawText.isEmpty) return TextSpan(style: style);

    final spans = <TextSpan>[];
    final pattern = _syntaxRegex;
    int lastEnd = 0;

    for (final match in pattern.allMatches(rawText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: rawText.substring(lastEnd, match.start),
          style: style?.copyWith(color: tokens.primaryText),
        ));
      }

      final matchedText = match.group(0)!;
      final color = _resolveColor(matchedText);
      spans.add(TextSpan(
        text: matchedText,
        style: style?.copyWith(
          color: color,
          fontWeight: _keywords.contains(matchedText)
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(lastEnd),
        style: style?.copyWith(color: tokens.primaryText),
      ));
    }

    return TextSpan(style: style, children: spans);
  }

  Color _resolveColor(String text) {
    if (text.startsWith('//') || text.startsWith('#') || text.startsWith('/*')) {
      return tokens.syntaxComment;
    }
    if (text.startsWith('"') || text.startsWith("'") || text.startsWith('`')) {
      return tokens.syntaxString;
    }
    if (RegExp(r'^\d').hasMatch(text)) return tokens.syntaxNumber;
    return _types.contains(text) ? tokens.syntaxType : tokens.syntaxKeyword;
  }

  static final RegExp _syntaxRegex = RegExp(
    r'(//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|'
    r"'(?:\\.|[^'\\])*'|`[^\`]*`|\b\d+(?:\.\d+)?\b|"
    r'\b(?:def|class|if|elif|else|while|for|in|return|break|continue|try|'
    r'except|finally|with|as|import|from|lambda|yield|pass|raise|assert|'
    r'True|False|None|function|const|let|var|switch|case|default|throw|'
    r'new|this|async|await|int|char|float|double|void|bool|struct|'
    r'namespace|using|public|private|protected|virtual|override|auto|'
    r'include|cout|cin|endl)\b)',
  );

  static const _keywords = {
    'def', 'class', 'if', 'elif', 'else', 'while', 'for', 'in', 'return',
    'break', 'continue', 'try', 'except', 'finally', 'with', 'as', 'import',
    'from', 'lambda', 'yield', 'pass', 'raise', 'assert', 'function', 'const',
    'let', 'var', 'switch', 'case', 'default', 'throw', 'new', 'this', 'async',
    'await', 'struct', 'namespace', 'using', 'public', 'private', 'virtual',
  };
  static const _types = {
    'int', 'char', 'float', 'double', 'void', 'bool', 'auto', 'size_t', 'string'
  };
}
