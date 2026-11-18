import 'package:flutter/material.dart';
import '../../competitive/widgets/problem_statement_panel.dart';
import '../../competitive/widgets/test_case_runner_panel.dart';
import '../../editor/widgets/code_editor_panel.dart';

class CompetitiveLayoutView extends StatelessWidget {
  const CompetitiveLayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return const Row(
            children: [
              // Left: Problem statement
              Expanded(
                flex: 4,
                child: ProblemStatementPanel(),
              ),
              VerticalDivider(width: 1),
              // Right: Code editor + Test cases
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: CodeEditorPanel(),
                    ),
                    Divider(height: 1),
                    Expanded(
                      flex: 4,
                      child: TestCaseRunnerPanel(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // Small screen: Tabbed view
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).cardColor,
                child: const TabBar(
                  tabs: [
                    Tab(
                        icon: Icon(Icons.description, size: 18),
                        text: 'Problem'),
                    Tab(icon: Icon(Icons.code, size: 18), text: 'Editor'),
                    Tab(icon: Icon(Icons.checklist, size: 18), text: 'Tests'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    ProblemStatementPanel(),
                    CodeEditorPanel(),
                    TestCaseRunnerPanel(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
