import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../editor/bloc/editor_bloc.dart';
import '../bloc/competitive_bloc.dart';
import '../models/problem_model.dart';

class ProblemStatementPanel extends StatelessWidget {
  const ProblemStatementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompetitiveBloc, CompetitiveState>(
      builder: (context, state) {
        final problem = state.activeProblem;

        return Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Problem selector dropdown
              Row(
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 20, color: PolyCodeTheme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ProblemModel>(
                        value: problem,
                        isExpanded: true,
                        items: ProblemModel.sampleProblems.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (selected) {
                          if (selected != null) {
                            context
                                .read<CompetitiveBloc>()
                                .add(SelectProblemRequested(selected));
                            final lang =
                                context.read<EditorBloc>().state.language;
                            final template = selected.starterTemplates[lang];
                            if (template != null) {
                              context
                                  .read<EditorBloc>()
                                  .add(SourceChanged(template));
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      problem.difficulty,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'Description',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      problem.description,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Constraints',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ...problem.constraints.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: PolyCodeTheme.accentColor)),
                            Expanded(
                              child: Text(
                                c,
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sample Input',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    _CodeCard(content: problem.sampleInput),
                    const SizedBox(height: 16),
                    const Text(
                      'Sample Output',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    _CodeCard(content: problem.sampleOutput),
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

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}
