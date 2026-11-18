import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../editor/bloc/editor_bloc.dart';
import '../../execution/bloc/execution_bloc.dart';
import '../bloc/competitive_bloc.dart';
import '../models/test_case_model.dart';

class TestCaseRunnerPanel extends StatefulWidget {
  const TestCaseRunnerPanel({super.key});

  @override
  State<TestCaseRunnerPanel> createState() => _TestCaseRunnerPanelState();
}

class _TestCaseRunnerPanelState extends State<TestCaseRunnerPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTestCaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTestCaseDialog(BuildContext context) {
    final inputCtrl = TextEditingController();
    final expectedCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Test Case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: inputCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Input (stdin)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expectedCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Expected Output',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (inputCtrl.text.isNotEmpty) {
                context.read<CompetitiveBloc>().add(
                      AddTestCaseRequested(
                        input: inputCtrl.text,
                        expectedOutput: expectedCtrl.text,
                      ),
                    );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompetitiveBloc, CompetitiveState>(
      builder: (context, state) {
        final cases = state.testCases;
        final selectedCase = _selectedTestCaseIndex < cases.length
            ? cases[_selectedTestCaseIndex]
            : null;

        return Column(
          children: [
            Container(
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Test Cases'),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: state.passedCount == cases.length &&
                                          cases.isNotEmpty
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : PolyCodeTheme.accentColor
                                          .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${state.passedCount}/${cases.length}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Tab(text: 'Custom Input'),
                      ],
                    ),
                  ),
                  // Add test case button
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Add Test Case',
                    onPressed: () => _showAddTestCaseDialog(context),
                  ),
                  // Run All button
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: state.isRunning
                          ? null
                          : () {
                              final editorState =
                                  context.read<EditorBloc>().state;
                              context.read<CompetitiveBloc>().add(
                                    RunAllTestCasesRequested(
                                      language: editorState.language,
                                      source: editorState.source,
                                    ),
                                  );
                            },
                      icon: state.isRunning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.playlist_play, size: 18),
                      label: const Text('Run Test Cases'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Test Cases Tab
                  Row(
                    children: [
                      // Test Case pill selector
                      Container(
                        width: 130,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: cases.length,
                          itemBuilder: (context, idx) {
                            final tc = cases[idx];
                            final isSelected = idx == _selectedTestCaseIndex;

                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                selected: isSelected,
                                title: Text(
                                  'Case ${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                leading: _verdictIcon(tc.verdict),
                                onTap: () {
                                  setState(() {
                                    _selectedTestCaseIndex = idx;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      // Selected Case detail
                      Expanded(
                        child: selectedCase == null
                            ? const Center(
                                child: Text('No test case selected.'))
                            : Padding(
                                padding: const EdgeInsets.all(12),
                                child: ListView(
                                  children: [
                                    Row(
                                      children: [
                                        _verdictBadge(selectedCase.verdict),
                                        const Spacer(),
                                        if (selectedCase.executionTime >
                                            Duration.zero)
                                          Text(
                                            '${selectedCase.executionTime.inMilliseconds} ms',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('Input:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    _OutputBox(text: selectedCase.input),
                                    const SizedBox(height: 10),
                                    const Text('Expected Output:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    _OutputBox(
                                        text: selectedCase.expectedOutput),
                                    const SizedBox(height: 10),
                                    const Text('Actual Output:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    _OutputBox(
                                      text: selectedCase.actualOutput.isNotEmpty
                                          ? selectedCase.actualOutput
                                          : (selectedCase.errorMessage ??
                                              'Not run yet'),
                                      isError: selectedCase.verdict ==
                                              TestCaseVerdict.wrongAnswer ||
                                          selectedCase.verdict ==
                                              TestCaseVerdict.runtimeError,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),

                  // Custom Input Tab
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: BlocBuilder<ExecutionBloc, ExecutionBlocState>(
                      builder: (context, execState) {
                        return TextField(
                          controller:
                              TextEditingController(text: execState.stdin),
                          onChanged: (val) {
                            context
                                .read<ExecutionBloc>()
                                .add(StdinChanged(val));
                          },
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter custom stdin input here...',
                            border: InputBorder.none,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _verdictIcon(TestCaseVerdict verdict) {
    switch (verdict) {
      case TestCaseVerdict.notRun:
        return const Icon(Icons.circle_outlined, size: 14, color: Colors.grey);
      case TestCaseVerdict.running:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TestCaseVerdict.accepted:
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case TestCaseVerdict.wrongAnswer:
        return const Icon(Icons.cancel, size: 16, color: Colors.red);
      case TestCaseVerdict.runtimeError:
      case TestCaseVerdict.timeLimitExceeded:
        return const Icon(Icons.error, size: 16, color: Colors.orange);
    }
  }

  Widget _verdictBadge(TestCaseVerdict verdict) {
    Color color;
    String label;
    switch (verdict) {
      case TestCaseVerdict.notRun:
        color = Colors.grey;
        label = 'NOT RUN';
        break;
      case TestCaseVerdict.running:
        color = PolyCodeTheme.accentColor;
        label = 'RUNNING';
        break;
      case TestCaseVerdict.accepted:
        color = Colors.green;
        label = 'ACCEPTED';
        break;
      case TestCaseVerdict.wrongAnswer:
        color = Colors.red;
        label = 'WRONG ANSWER';
        break;
      case TestCaseVerdict.runtimeError:
        color = Colors.orange;
        label = 'RUNTIME ERROR';
        break;
      case TestCaseVerdict.timeLimitExceeded:
        color = Colors.purple;
        label = 'TIME LIMIT EXCEEDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OutputBox extends StatelessWidget {
  const _OutputBox({required this.text, this.isError = false});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: isError ? Colors.redAccent : null,
        ),
      ),
    );
  }
}
