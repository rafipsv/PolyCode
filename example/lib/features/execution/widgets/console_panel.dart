import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../bloc/execution_bloc.dart';

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({super.key});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.polyTheme;

    return BlocBuilder<ExecutionBloc, ExecutionBlocState>(
      builder: (context, state) {
        return Container(
          color: tokens.terminalBackground,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: tokens.panelHeader,
                  border: Border(
                    bottom: BorderSide(color: tokens.border, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: tokens.primaryText,
                  unselectedLabelColor: tokens.secondaryText,
                  indicatorColor: tokens.accent,
                  tabs: [
                    Tab(text: 'Output (${state.stdout.length} chars)'),
                    Tab(text: 'Errors (${state.stderr.length})'),
                    const Tab(text: 'Input (stdin)'),
                    Tab(text: 'Diagnostics (${state.diagnostics.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTextScroll(
                      state.stdout.isEmpty
                          ? 'Press "Run" to execute code locally.'
                          : state.stdout,
                      tokens,
                    ),
                    _buildTextScroll(
                      state.stderr.isEmpty
                          ? 'No errors reported.'
                          : state.stderr,
                      tokens,
                      isError: state.stderr.isNotEmpty,
                    ),
                    _buildStdinInput(context, state, tokens),
                    _buildDiagnosticsList(state, tokens),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextScroll(String text, PolyCodeThemeTokens tokens,
      {bool isError = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isError ? tokens.error : tokens.terminalForeground,
        ),
      ),
    );
  }

  Widget _buildStdinInput(
    BuildContext context,
    ExecutionBlocState state,
    PolyCodeThemeTokens tokens,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: tokens.primaryText,
        ),
        decoration: InputDecoration(
          hintText: 'Enter custom standard input (stdin) lines here...',
          hintStyle: TextStyle(color: tokens.mutedText),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: tokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: tokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: tokens.accent),
          ),
        ),
        onChanged: (val) {
          context.read<ExecutionBloc>().add(StdinChanged(val));
        },
      ),
    );
  }

  Widget _buildDiagnosticsList(
      ExecutionBlocState state, PolyCodeThemeTokens tokens) {
    if (state.diagnostics.isEmpty) {
      return Center(
        child: Text(
          'No compiler diagnostics.',
          style: TextStyle(color: tokens.secondaryText),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.diagnostics.length,
      itemBuilder: (context, idx) {
        final d = state.diagnostics[idx];
        return ListTile(
          dense: true,
          leading: Icon(Icons.error_outline, color: tokens.error, size: 18),
          title: Text(
            d.message,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: tokens.primaryText,
            ),
          ),
          subtitle: d.line != null
              ? Text(
                  'Line ${d.line}, Column ${d.column ?? 1}',
                  style: TextStyle(color: tokens.mutedText),
                )
              : null,
        );
      },
    );
  }
}
