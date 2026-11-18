import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import '../editor/bloc/editor_bloc.dart';
import '../execution/bloc/execution_bloc.dart';
import '../layouts/bloc/layout_bloc.dart';
import '../layouts/models/workspace_layout.dart';
import '../layouts/views/code_block_layout_view.dart';
import '../layouts/views/competitive_layout_view.dart';
import '../layouts/views/ide_layout_view.dart';
import 'polycode_app_bar.dart';
import 'status_bar.dart';

class PolyCodeShell extends StatelessWidget {
  const PolyCodeShell({super.key, required this.polycode});

  final PolyCode polycode;

  void _triggerRun(BuildContext context) {
    final editorState = context.read<EditorBloc>().state;
    context.read<ExecutionBloc>().add(
          ExecuteRequested(
            language: editorState.language,
            source: editorState.source,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
            _triggerRun(context),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () =>
            _triggerRun(context),
      },
      child: Focus(
        autofocus: true,
        child: BlocListener<ExecutionBloc, ExecutionBlocState>(
          listenWhen: (previous, current) =>
              previous.isRunning && !current.isRunning,
          listener: (context, state) {
            final isSuccess =
                state.status == ExecutionStatus.completed && state.exitCode == 0;
            final message = isSuccess
                ? 'Code execution finished successfully (Exit code: 0).'
                : 'Code execution failed (Exit code: ${state.exitCode ?? 1}).';
            try {
              SemanticsService.sendAnnouncement(
                View.of(context),
                message,
                TextDirection.ltr,
              );
            } catch (_) {}
          },
          child: Scaffold(
            appBar: PolyCodeAppBar(polycode: polycode),
            body: BlocBuilder<LayoutBloc, LayoutState>(
              builder: (context, state) {
                switch (state.activeLayout) {
                  case WorkspaceLayout.competitive:
                    return const CompetitiveLayoutView();
                  case WorkspaceLayout.codeBlock:
                    return const CodeBlockLayoutView();
                  case WorkspaceLayout.ide:
                    return const IdeLayoutView();
                }
              },
            ),
            bottomNavigationBar: StatusBar(polycode: polycode),
          ),
        ),
      ),
    );
  }
}
