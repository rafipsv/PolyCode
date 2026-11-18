import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../editor/bloc/editor_bloc.dart';
import '../../execution/bloc/execution_bloc.dart';
import '../bloc/layout_bloc.dart';

class CodeBlockLayoutView extends StatefulWidget {
  const CodeBlockLayoutView({super.key});

  @override
  State<CodeBlockLayoutView> createState() => _CodeBlockLayoutViewState();
}

class _CodeBlockLayoutViewState extends State<CodeBlockLayoutView> {
  bool _isOutputExpanded = true;
  bool _showStdinInput = false;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    final initialSource = context.read<EditorBloc>().state.source;
    _codeController = TextEditingController(text: initialSource);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditorBloc, EditorState>(
      listener: (context, state) {
        if (_codeController.text != state.source) {
          _codeController.text = state.source;
        }
      },
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<LayoutBloc, LayoutState>(
            builder: (context, layoutState) {
              return BlocBuilder<EditorBloc, EditorState>(
                builder: (context, editorState) {
                  return BlocBuilder<ExecutionBloc, ExecutionBlocState>(
                    builder: (context, execState) {
                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Header
                            _buildHeader(
                              context,
                              editorState,
                              layoutState,
                              execState,
                            ),
                            const Divider(height: 1),

                            // Code editor body
                            Container(
                              height: 320,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: _codeController,
                                readOnly: layoutState.isReadOnly,
                                maxLines: null,
                                expands: true,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: layoutState.fontSize,
                                  height: 1.4,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  context
                                      .read<EditorBloc>()
                                      .add(SourceChanged(val));
                                },
                              ),
                            ),

                            // Stdin input section if enabled
                            if (_showStdinInput) ...[
                              const Divider(height: 1),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                color: Theme.of(context).cardColor,
                                child: Row(
                                  children: [
                                    const Text(
                                      'stdin:',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Input passed to program...',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.all(8),
                                        ),
                                        controller: TextEditingController(
                                            text: execState.stdin),
                                        onChanged: (val) {
                                          context
                                              .read<ExecutionBloc>()
                                              .add(StdinChanged(val));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Output section (collapsible)
                            const Divider(height: 1),
                            _buildOutputBar(context, execState),
                            if (_isOutputExpanded)
                              _buildOutputBody(context, execState),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EditorState editorState,
    LayoutState layoutState,
    ExecutionBlocState execState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          // Language Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PolyCodeTheme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.code,
                    size: 14, color: PolyCodeTheme.accentColor),
                const SizedBox(width: 6),
                Text(
                  editorState.language.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: PolyCodeTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Read-only indicator
          if (layoutState.isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'READ-ONLY',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),

          const Spacer(),

          // Stdin toggle button
          IconButton(
            icon: Icon(
              Icons.input,
              size: 18,
              color: _showStdinInput ? PolyCodeTheme.accentColor : null,
            ),
            tooltip: 'Toggle Stdin Input',
            onPressed: () {
              setState(() {
                _showStdinInput = !_showStdinInput;
              });
            },
          ),

          // Read-only toggle button
          IconButton(
            icon: Icon(
              layoutState.isReadOnly ? Icons.lock : Icons.lock_open_outlined,
              size: 18,
            ),
            tooltip:
                layoutState.isReadOnly ? 'Unlock Editor' : 'Lock (Read-Only)',
            onPressed: () {
              context
                  .read<LayoutBloc>()
                  .add(SetReadOnlyMode(!layoutState.isReadOnly));
            },
          ),

          // Copy button
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Copy Code',
            onPressed: () => _copyCode(context, editorState.source),
          ),

          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Reset Template',
            onPressed: () {
              context.read<EditorBloc>().add(const ResetTemplateRequested());
            },
          ),

          const SizedBox(width: 4),

          // Run / Stop button
          if (execState.isRunning)
            IconButton.filled(
              icon: const Icon(Icons.stop, size: 16),
              style: IconButton.styleFrom(
                  backgroundColor: PolyCodeTheme.errorColor),
              onPressed: () {
                context.read<ExecutionBloc>().add(const StopRequested());
              },
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PolyCodeTheme.accentColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () {
                context.read<ExecutionBloc>().add(
                      ExecuteRequested(
                        language: editorState.language,
                        source: editorState.source,
                        stdin: execState.stdin,
                      ),
                    );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOutputBar(BuildContext context, ExecutionBlocState execState) {
    return InkWell(
      onTap: () {
        setState(() {
          _isOutputExpanded = !_isOutputExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            Icon(
              _isOutputExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              size: 18,
            ),
            const SizedBox(width: 4),
            const Text(
              'Output',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (execState.duration > Duration.zero)
              Text(
                '${execState.duration.inMilliseconds} ms',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            const Spacer(),
            if (execState.exitCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: execState.exitCode == 0
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Exit ${execState.exitCode}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: execState.exitCode == 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputBody(BuildContext context, ExecutionBlocState execState) {
    final text = execState.stdout.isNotEmpty
        ? execState.stdout
        : (execState.stderr.isNotEmpty
            ? execState.stderr
            : (execState.isRunning
                ? 'Executing...'
                : 'Run code to see output here.'));

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: execState.stderr.isNotEmpty ? Colors.redAccent : null,
          ),
        ),
      ),
    );
  }
}
