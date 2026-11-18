import 'package:polycode/polycode.dart';

class IdeState {
  const IdeState({
    required this.files,
    required this.activeFileName,
    required this.openTabs,
    this.isSearchOpen = false,
    this.searchQuery = '',
  });

  final Map<String, SourceFile> files;
  final String activeFileName;
  final List<String> openTabs;
  final bool isSearchOpen;
  final String searchQuery;

  SourceFile? get activeFile => files[activeFileName];

  IdeState copyWith({
    Map<String, SourceFile>? files,
    String? activeFileName,
    List<String>? openTabs,
    bool? isSearchOpen,
    String? searchQuery,
  }) {
    return IdeState(
      files: files ?? this.files,
      activeFileName: activeFileName ?? this.activeFileName,
      openTabs: openTabs ?? this.openTabs,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  static IdeState defaultState(PolyLanguage language) {
    final entryName = _entryForLanguage(language);
    final helperName = _helperForLanguage(language);
    final files = {
      entryName: SourceFile(
        name: entryName,
        content: _demoMain(language),
        isEntry: true,
      ),
      helperName: SourceFile(
        name: helperName,
        content: _demoHelper(language),
      ),
      'README.md': const SourceFile(
        name: 'README.md',
        content: '# PolyCode Virtual Workspace\nEdit multiple files locally.',
      ),
    };
    return IdeState(
      files: files,
      activeFileName: entryName,
      openTabs: [entryName, helperName],
    );
  }

  static String _entryForLanguage(PolyLanguage l) {
    switch (l) {
      case PolyLanguage.python:
        return 'main.py';
      case PolyLanguage.javascript:
        return 'index.js';
      case PolyLanguage.c:
        return 'main.c';
      case PolyLanguage.cpp:
        return 'main.cpp';
      default:
        return 'main.txt';
    }
  }

  static String _helperForLanguage(PolyLanguage l) {
    switch (l) {
      case PolyLanguage.python:
        return 'utils.py';
      case PolyLanguage.javascript:
        return 'helpers.js';
      case PolyLanguage.c:
        return 'math_utils.h';
      case PolyLanguage.cpp:
        return 'math_utils.hpp';
      default:
        return 'notes.txt';
    }
  }

  static String _demoMain(PolyLanguage l) {
    switch (l) {
      case PolyLanguage.python:
        return 'import utils\n\nprint("Greeting:", utils.say_hello("PolyCode"))\nprint("Square of 7:", utils.square(7))\n';
      case PolyLanguage.javascript:
        return '// PolyCode Multi-file Workspace\nconsole.log("Hello from index.js!");\nconst sum = (a, b) => a + b;\nconsole.log("Sum:", sum(10, 25));\n';
      case PolyLanguage.c:
        return '#include <stdio.h>\n\nint main() {\n    printf("Multi-file C workspace ready.\\n");\n    return 0;\n}\n';
      case PolyLanguage.cpp:
        return '#include <iostream>\n\nint main() {\n    std::cout << "Multi-file C++ workspace ready." << std::endl;\n    return 0;\n}\n';
      default:
        return '// PolyCode Workspace\n';
    }
  }

  static String _demoHelper(PolyLanguage l) {
    switch (l) {
      case PolyLanguage.python:
        return 'def say_hello(name):\n    return f"Hello, {name}!"\n\ndef square(n):\n    return n * n\n';
      case PolyLanguage.javascript:
        return 'export function greet(name) {\n    return "Welcome, " + name;\n}\n';
      case PolyLanguage.c:
        return '#ifndef MATH_UTILS_H\n#define MATH_UTILS_H\nint add(int a, int b) { return a + b; }\n#endif\n';
      case PolyLanguage.cpp:
        return '#pragma once\ninline int multiply(int a, int b) { return a * b; }\n';
      default:
        return 'Notes:\n';
    }
  }
}
