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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? PolyCodeTheme.darkTerminalBackground
        : PolyCodeTheme.lightTerminalBackground;

    return BlocBuilder<ExecutionBloc, ExecutionBlocState>(
      builder: (context, state) {
        return Container(
          color: bg,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: 'Output (${state.stdout.length} chars)'),
                  Tab(text: 'Errors (${state.stderr.length})'),
                  const Tab(text: 'Input (stdin)'),
                  Tab(text: 'Diagnostics (${state.diagnostics.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTextScroll(
                      state.stdout.isEmpty
                          ? 'Press "Run" to execute code locally.'
                          : state.stdout,
                      isDark,
                    ),
                    _buildTextScroll(
                      state.stderr.isEmpty
                          ? 'No errors reported.'
                          : state.stderr,
                      isDark,
                      isError: state.stderr.isNotEmpty,
                    ),
                    _buildStdinInput(context, state, isDark),
                    _buildDiagnosticsList(state, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextScroll(String text, bool isDark, {bool isError = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isError
              ? PolyCodeTheme.errorColor
              : (isDark
                  ? PolyCodeTheme.darkTextPrimary
                  : PolyCodeTheme.lightTextPrimary),
        ),
      ),
    );
  }

  Widget _buildStdinInput(
      BuildContext context, ExecutionBlocState state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Enter custom standard input (stdin) lines here...',
          border: OutlineInputBorder(),
        ),
        onChanged: (val) {
          context.read<ExecutionBloc>().add(StdinChanged(val));
        },
      ),
    );
  }

  Widget _buildDiagnosticsList(ExecutionBlocState state, bool isDark) {
    if (state.diagnostics.isEmpty) {
      return const Center(child: Text('No compiler diagnostics.'));
    }

    return ListView.builder(
      itemCount: state.diagnostics.length,
      itemBuilder: (context, idx) {
        final d = state.diagnostics[idx];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline,
              color: PolyCodeTheme.errorColor, size: 18),
          title: Text(
            d.message,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
          subtitle: d.line != null
              ? Text('Line ${d.line}, Column ${d.column ?? 1}')
              : null,
        );
      },
    );
  }
}
