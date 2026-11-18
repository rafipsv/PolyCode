import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../editor/bloc/editor_bloc.dart';
import '../bloc/ide_workspace_bloc.dart';

class IdeFileExplorer extends StatelessWidget {
  const IdeFileExplorer({super.key});

  void _showCreateFileDialog(BuildContext context) {
    final nameCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New File'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. script.py, helper.js, data.txt',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                context.read<IdeWorkspaceBloc>().add(CreateFileRequested(name));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _exportProject(BuildContext context, IdeState state) {
    final exportData =
        state.files.map((key, val) => MapEntry(key, val.content));
    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Workspace (JSON Bundle)'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All virtual workspace files in JSON format:'),
              const SizedBox(height: 8),
              Container(
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdeWorkspaceBloc, IdeState>(
      builder: (context, state) {
        final sortedKeys = state.files.keys.toList()..sort();

        return Container(
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'EXPLORER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(24, 24),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.note_add_outlined, size: 16),
                      tooltip: 'New File',
                      onPressed: () => _showCreateFileDialog(context),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(24, 24),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      tooltip: 'Export Workspace',
                      onPressed: () => _exportProject(context, state),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(24, 24),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      tooltip: 'Reset Demo Workspace',
                      onPressed: () {
                        final lang = context.read<EditorBloc>().state.language;
                        context
                            .read<IdeWorkspaceBloc>()
                            .add(LoadDemoProjectRequested(lang));
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Files list
              Expanded(
                child: ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, idx) {
                    final fileName = sortedKeys[idx];
                    final file = state.files[fileName]!;
                    final isSelected = fileName == state.activeFileName;

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        selected: isSelected,
                        selectedTileColor:
                            PolyCodeTheme.accentColor.withValues(alpha: 0.15),
                        leading: Icon(
                          _fileIcon(fileName),
                          size: 16,
                          color: _fileColor(fileName),
                        ),
                        title: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: sortedKeys.length > 1
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                tooltip: 'Delete File',
                                onPressed: () {
                                  context
                                      .read<IdeWorkspaceBloc>()
                                      .add(DeleteFileRequested(fileName));
                                },
                              )
                            : null,
                        onTap: () {
                          context
                              .read<IdeWorkspaceBloc>()
                              .add(SelectFileRequested(fileName));
                          // Sync with EditorBloc
                          context
                              .read<EditorBloc>()
                              .add(SourceChanged(file.content));
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _fileIcon(String name) {
    if (name.endsWith('.py')) return Icons.code;
    if (name.endsWith('.js')) return Icons.javascript;
    if (name.endsWith('.c') || name.endsWith('.cpp') || name.endsWith('.h')) {
      return Icons.memory;
    }
    if (name.endsWith('.md') || name.endsWith('.txt')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _fileColor(String name) {
    if (name.endsWith('.py')) return Colors.blue;
    if (name.endsWith('.js')) return Colors.amber;
    if (name.endsWith('.c') || name.endsWith('.cpp') || name.endsWith('.h')) {
      return Colors.cyan;
    }
    if (name.endsWith('.md')) return Colors.orange;
    return Colors.grey;
  }
}
