import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import '../../execution/bloc/execution_bloc.dart';

class IdeProblemsPanel extends StatelessWidget {
  const IdeProblemsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExecutionBloc, ExecutionBlocState>(
      builder: (context, state) {
        final diagnostics = state.diagnostics;

        if (diagnostics.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 36,
                  color: Colors.green.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No problems detected in the current workspace.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: diagnostics.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            final diag = diagnostics[idx];

            return ListTile(
              dense: true,
              leading: _severityIcon(diag.severity),
              title: Text(
                diag.message,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Line ${diag.line ?? '?'}, Column ${diag.column ?? '?'}${diag.fileName != null ? ' in ${diag.fileName}' : ''}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _severityIcon(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.error:
        return const Icon(Icons.error_outline, size: 16, color: Colors.red);
      case DiagnosticSeverity.warning:
        return const Icon(Icons.warning_amber_outlined,
            size: 16, color: Colors.orange);
      case DiagnosticSeverity.info:
        return const Icon(Icons.info_outline, size: 16, color: Colors.blue);
    }
  }
}
