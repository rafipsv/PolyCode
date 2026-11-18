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
    final tokens = context.polyTheme;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return AppBar(
          titleSpacing: 8,
          backgroundColor: tokens.panelHeader,
          foregroundColor: tokens.primaryText,
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
                      color: tokens.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.terminal,
                      color: tokens.accent,
                      size: 18,
                    ),
                  ),
                  if (constraints.maxWidth >= 100) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'PolyCode',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tokens.primaryText,
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
                return Semantics(
                  label: 'Workspace Layout Selector',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (layoutState.activeLayout == WorkspaceLayout.ide)
                        IconButton(
                          icon:
                              const Icon(Icons.view_sidebar_outlined, size: 18),
                          tooltip: 'Toggle File Explorer',
                          onPressed: () {
                            context
                                .read<LayoutBloc>()
                                .add(const ToggleSidebar());
                          },
                        ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<WorkspaceLayout>(
                          value: layoutState.activeLayout,
                          dropdownColor: tokens.panelBackground,
                          items: WorkspaceLayout.values.map((layout) {
                            return DropdownMenuItem(
                              value: layout,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(layout.icon,
                                      size: 16, color: tokens.primaryText),
                                  const SizedBox(width: 6),
                                  Text(
                                    layout.displayName,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.primaryText),
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
                  ),
                );
              },
            ),
            const SizedBox(width: 6),

            // Language Selector
            BlocBuilder<EditorBloc, EditorState>(
              builder: (context, editorState) {
                return Semantics(
                  label: 'Language Selector',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PolyLanguage>(
                      value: editorState.language,
                      dropdownColor: tokens.panelBackground,
                      items: PolyLanguage.values.map((lang) {
                        final isRunnable = polycode.isEngineAvailable(lang);
                        return DropdownMenuItem(
                          value: lang,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang.displayName,
                                style: TextStyle(color: tokens.primaryText),
                              ),
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
                                    color: isRunnable
                                        ? Colors.green
                                        : Colors.orange,
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
                  ),
                );
              },
            ),
            const SizedBox(width: 6),

            // Run / Stop Actions
            BlocBuilder<ExecutionBloc, ExecutionBlocState>(
              builder: (context, execState) {
                if (execState.isRunning) {
                  return Semantics(
                    button: true,
                    label: 'Stop Execution',
                    child: IconButton.filled(
                      onPressed: () {
                        context
                            .read<ExecutionBloc>()
                            .add(const StopRequested());
                      },
                      icon: const Icon(Icons.stop),
                      style: IconButton.styleFrom(
                        backgroundColor: tokens.error,
                      ),
                      tooltip: 'Stop execution',
                    ),
                  );
                }

                return Semantics(
                  button: true,
                  label: 'Run Code in Local Sandbox (Ctrl+Enter or Cmd+Enter)',
                  child: ElevatedButton.icon(
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
                      backgroundColor: tokens.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),

            // Clear Output
            Semantics(
              button: true,
              label: 'Clear Output and Terminal',
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Clear Output',
                onPressed: () {
                  context
                      .read<ExecutionBloc>()
                      .add(const ClearOutputRequested());
                },
              ),
            ),

            // Theme Preset & Mode Selector Menu
            PopupMenuButton<String>(
              icon: Icon(
                themeState.mode == ThemeMode.system
                    ? Icons.brightness_auto
                    : (themeState.isDark ? Icons.dark_mode : Icons.light_mode),
                size: 20,
                color: tokens.primaryText,
              ),
              tooltip: 'Theme & Preferences',
              color: tokens.panelBackground,
              onSelected: (choice) {
                final themeBloc = context.read<ThemeBloc>();
                switch (choice) {
                  case 'system':
                    themeBloc
                        .add(const SetThemeModeRequested(ThemeMode.system));
                    break;
                  case 'dark':
                    themeBloc.add(
                      const SetThemePresetRequested(PolyCodeThemePreset.dark),
                    );
                    break;
                  case 'light':
                    themeBloc.add(
                      const SetThemePresetRequested(PolyCodeThemePreset.light),
                    );
                    break;
                  case 'highContrast':
                    themeBloc.add(
                      const SetThemePresetRequested(
                          PolyCodeThemePreset.highContrast),
                    );
                    break;
                }
              },
              itemBuilder: (ctx) => [
                CheckedPopupMenuItem(
                  value: 'dark',
                  checked: themeState.preset == PolyCodeThemePreset.dark &&
                      themeState.mode == ThemeMode.dark,
                  child: Text('Dark Theme',
                      style: TextStyle(color: tokens.primaryText)),
                ),
                CheckedPopupMenuItem(
                  value: 'light',
                  checked: themeState.preset == PolyCodeThemePreset.light &&
                      themeState.mode == ThemeMode.light,
                  child: Text('Light Theme',
                      style: TextStyle(color: tokens.primaryText)),
                ),
                CheckedPopupMenuItem(
                  value: 'highContrast',
                  checked:
                      themeState.preset == PolyCodeThemePreset.highContrast,
                  child: Text('High Contrast (A11y)',
                      style: TextStyle(color: tokens.primaryText)),
                ),
                const PopupMenuDivider(),
                CheckedPopupMenuItem(
                  value: 'system',
                  checked: themeState.mode == ThemeMode.system,
                  child: Text('Follow System Mode',
                      style: TextStyle(color: tokens.primaryText)),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
