import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../bloc/editor_bloc.dart';

class CodeEditorPanel extends StatefulWidget {
  const CodeEditorPanel({super.key});

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<EditorBloc>().state.source,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? PolyCodeTheme.darkEditorBackground
        : PolyCodeTheme.lightEditorBackground;

    return BlocListener<EditorBloc, EditorState>(
      listenWhen: (prev, current) =>
          prev.language != current.language || !current.isDirty,
      listener: (context, state) {
        if (_controller.text != state.source) {
          _controller.text = state.source;
        }
      },
      child: Container(
        color: bg,
        child: Column(
          children: [
            // Editor Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isDark
                  ? PolyCodeTheme.darkPanelHeader
                  : PolyCodeTheme.lightPanelHeader,
              child: Row(
                children: [
                  BlocBuilder<EditorBloc, EditorState>(
                    builder: (context, state) {
                      return Text(
                        'main.${state.language.extension}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
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
                  maxLines: null,
                  expands: true,
                  onChanged: (val) {
                    context.read<EditorBloc>().add(SourceChanged(val));
                  },
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    height: 1.45,
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
      ),
    );
  }
}
