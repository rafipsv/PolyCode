import 'package:flutter/material.dart';
import 'package:polycode/polycode.dart';
import '../../../core/theme/polycode_theme_tokens.dart';
import 'syntax_tokens.dart';

/// Lightweight syntax highlighting controller adhering to active theme tokens.
class SyntaxHighlighterEditingController extends TextEditingController {
  SyntaxHighlighterEditingController({
    super.text,
    required this.language,
    required this.tokens,
  });

  PolyLanguage language;
  PolyCodeThemeTokens tokens;

  void updateThemeAndLanguage(
      PolyLanguage newLang, PolyCodeThemeTokens newTokens) {
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
    int lastEnd = 0;

    for (final match in syntaxRegex.allMatches(rawText)) {
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
          fontWeight: syntaxKeywords.contains(matchedText)
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
    if (text.startsWith('//') ||
        text.startsWith('#') ||
        text.startsWith('/*')) {
      return tokens.syntaxComment;
    }
    if (text.startsWith('"') || text.startsWith("'") || text.startsWith('`')) {
      return tokens.syntaxString;
    }
    if (RegExp(r'^\d').hasMatch(text)) return tokens.syntaxNumber;
    return syntaxTypes.contains(text)
        ? tokens.syntaxType
        : tokens.syntaxKeyword;
  }
}
