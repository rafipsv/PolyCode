import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../editor/bloc/editor_bloc.dart';
import '../../editor/widgets/code_editor_panel.dart';
import '../../execution/bloc/execution_bloc.dart';
import '../../execution/widgets/console_panel.dart';
import '../../ide/bloc/ide_workspace_bloc.dart';
import '../../ide/widgets/ide_file_explorer.dart';
import '../../ide/widgets/ide_problems_panel.dart';
import '../../ide/widgets/ide_tab_bar.dart';
import '../bloc/layout_bloc.dart';

class IdeLayoutView extends StatefulWidget {
  const IdeLayoutView({super.key});

  @override
  State<IdeLayoutView> createState() => _IdeLayoutViewState();
}

class _IdeLayoutViewState extends State<IdeLayoutView>
    with SingleTickerProviderStateMixin {
  late final TabController _bottomTabController;

  @override
  void initState() {
    super.initState();
    _bottomTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _bottomTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LayoutBloc, LayoutState>(
      builder: (context, layoutState) {
        return BlocBuilder<IdeWorkspaceBloc, IdeState>(
          builder: (context, ideState) {
            return BlocBuilder<ExecutionBloc, ExecutionBlocState>(
              builder: (context, execState) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 800;

                    return Row(
                      children: [
                        // Left Sidebar: File Explorer
                        if (layoutState.isSidebarOpen) ...[
                          SizedBox(
                            width: isDesktop ? 220 : 180,
                            child: const IdeFileExplorer(),
                          ),
                          const VerticalDivider(width: 1),
                        ],

                        // Main Workspace Center
                        Expanded(
                          child: Column(
                            children: [
                              // Tab bar
                              const IdeTabBar(),
                              const Divider(height: 1),

                              // Quick search bar if open
                              if (ideState.isSearchOpen) ...[
                                _buildSearchBar(context, ideState),
                                const Divider(height: 1),
                              ],

                              // Code Editor
                              const Expanded(
                                flex: 6,
                                child: CodeEditorPanel(),
                              ),

                              // Bottom Panel (Terminal / Problems / Stdin)
                              if (layoutState.isBottomPanelOpen) ...[
                                const Divider(height: 1),
                                Expanded(
                                  flex: 4,
                                  child: _buildBottomPanel(
                                    context,
                                    execState,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, IdeState state) {
    final editorSource = context.read<EditorBloc>().state.source;
    final query = state.searchQuery;
    final matchCount = query.isEmpty
        ? 0
        : RegExp.escape(query).allMatches(editorSource).length;

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: PolyCodeTheme.accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Find in active file...',
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                context.read<IdeWorkspaceBloc>().add(SearchQueryChanged(val));
              },
            ),
          ),
          if (query.isNotEmpty)
            Text(
              '$matchCount matches',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close Search',
            onPressed: () {
              context
                  .read<IdeWorkspaceBloc>()
                  .add(const ToggleSearchRequested());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    ExecutionBlocState execState,
  ) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _bottomTabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(text: 'OUTPUT / TERMINAL'),
                    const Tab(text: 'INPUT (STDIN)'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('PROBLEMS'),
                          if (execState.diagnostics.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${execState.diagnostics.length}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                tooltip: 'Collapse Bottom Panel',
                onPressed: () {
                  context.read<LayoutBloc>().add(const ToggleBottomPanel());
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _bottomTabController,
            children: [
              // Terminal Output
              const ConsolePanel(),

              // Custom Stdin
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: TextEditingController(text: execState.stdin),
                  onChanged: (val) {
                    context.read<ExecutionBloc>().add(StdinChanged(val));
                  },
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Enter stdin for program execution...',
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Problems
              const IdeProblemsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
