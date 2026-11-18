import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../layouts/bloc/layout_bloc.dart';
import '../bloc/editor_bloc.dart';
import 'syntax_highlighter_controller.dart';

class CodeEditorPanel extends StatefulWidget {
  const CodeEditorPanel({super.key});

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  late final SyntaxHighlighterEditingController _controller;

  @override
  void initState() {
    super.initState();
    final editorState = context.read<EditorBloc>().state;
    _controller = SyntaxHighlighterEditingController(
      text: editorState.source,
      language: editorState.language,
      tokens: PolyCodeThemeTokens.dark,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.polyTheme;

    return BlocListener<EditorBloc, EditorState>(
      listenWhen: (prev, current) =>
          prev.language != current.language || !current.isDirty,
      listener: (context, state) {
        if (_controller.text != state.source) {
          _controller.text = state.source;
        }
      },
      child: BlocBuilder<LayoutBloc, LayoutState>(
        builder: (context, layoutState) {
          return BlocBuilder<EditorBloc, EditorState>(
            builder: (context, editorState) {
              _controller.updateThemeAndLanguage(editorState.language, tokens);

              return Container(
                color: tokens.editorBackground,
                child: Column(
                  children: [
                    // Editor Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tokens.panelHeader,
                        border: Border(
                          bottom: BorderSide(color: tokens.border, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'main.${editorState.language.extension}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: tokens.primaryText,
                            ),
                          ),
                          const Spacer(),
                          // Font zoom controls
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14),
                            tooltip: 'Decrease font size',
                            onPressed: () {
                              context
                                  .read<LayoutBloc>()
                                  .add(const ChangeEditorFontSize(-1.0));
                            },
                          ),
                          Text(
                            '${layoutState.fontSize.toInt()}px',
                            style: TextStyle(
                                fontSize: 11, color: tokens.secondaryText),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            tooltip: 'Increase font size',
                            onPressed: () {
                              context
                                  .read<LayoutBloc>()
                                  .add(const ChangeEditorFontSize(1.0));
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.restart_alt, size: 16),
                            tooltip: 'Reset to Starter Template',
                            onPressed: () {
                              context
                                  .read<EditorBloc>()
                                  .add(const ResetTemplateRequested());
                            },
                          ),
                        ],
                      ),
                    ),
                    // Editor Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _controller,
                          readOnly: layoutState.isReadOnly,
                          maxLines: null,
                          expands: true,
                          cursorColor: tokens.cursor,
                          onChanged: (val) {
                            context.read<EditorBloc>().add(SourceChanged(val));
                          },
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: layoutState.fontSize,
                            height: 1.45,
                            color: tokens.primaryText,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
