import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import '../../core/theme/polycode_theme.dart';
import '../editor/bloc/editor_bloc.dart';
import '../execution/bloc/execution_bloc.dart';
import '../layouts/bloc/layout_bloc.dart';
import '../layouts/models/workspace_layout.dart';
import '../themes/bloc/theme_bloc.dart';

class PolyCodeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PolyCodeAppBar({super.key, required this.polycode});

  final PolyCode polycode;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return AppBar(
          titleSpacing: 8,
          title: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 40) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: PolyCodeTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.terminal,
                      color: PolyCodeTheme.accentColor,
                      size: 18,
                    ),
                  ),
                  if (constraints.maxWidth >= 100) ...[
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'PolyCode',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            // Workspace Layout Selector
            BlocBuilder<LayoutBloc, LayoutState>(
              builder: (context, layoutState) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (layoutState.activeLayout == WorkspaceLayout.ide)
                      IconButton(
                        icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                        tooltip: 'Toggle File Explorer',
                        onPressed: () {
                          context.read<LayoutBloc>().add(const ToggleSidebar());
                        },
                      ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<WorkspaceLayout>(
                        value: layoutState.activeLayout,
                        items: WorkspaceLayout.values.map((layout) {
                          return DropdownMenuItem(
                            value: layout,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(layout.icon, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  layout.displayName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (layout) {
                          if (layout != null) {
                            context
                                .read<LayoutBloc>()
                                .add(SwitchLayout(layout));
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 6),

            // Language Selector
            BlocBuilder<EditorBloc, EditorState>(
              builder: (context, editorState) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<PolyLanguage>(
                    value: editorState.language,
                    items: PolyLanguage.values.map((lang) {
                      final isRunnable = polycode.isEngineAvailable(lang);
                      return DropdownMenuItem(
                        value: lang,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(lang.displayName),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isRunnable
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isRunnable ? 'Ready' : 'Planned',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isRunnable ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (lang) {
                      if (lang != null) {
                        context.read<EditorBloc>().add(LanguageChanged(lang));
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 6),

            // Run / Stop Actions
            BlocBuilder<ExecutionBloc, ExecutionBlocState>(
              builder: (context, execState) {
                if (execState.isRunning) {
                  return IconButton.filled(
                    onPressed: () {
                      context.read<ExecutionBloc>().add(const StopRequested());
                    },
                    icon: const Icon(Icons.stop),
                    style: IconButton.styleFrom(
                      backgroundColor: PolyCodeTheme.errorColor,
                    ),
                    tooltip: 'Stop execution',
                  );
                }

                return ElevatedButton.icon(
                  onPressed: () {
                    final editorState = context.read<EditorBloc>().state;
                    context.read<ExecutionBloc>().add(
                          ExecuteRequested(
                            language: editorState.language,
                            source: editorState.source,
                          ),
                        );
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PolyCodeTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),

            // Clear Output
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear Output',
              onPressed: () {
                context.read<ExecutionBloc>().add(const ClearOutputRequested());
              },
            ),

            // Theme Toggle
            IconButton(
              icon: Icon(
                themeState.isDark ? Icons.light_mode : Icons.dark_mode,
                size: 20,
              ),
              tooltip: 'Toggle Theme',
              onPressed: () {
                context.read<ThemeBloc>().add(const ToggleThemeRequested());
              },
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
