import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import '../../core/theme/polycode_theme.dart';
import '../editor/bloc/editor_bloc.dart';
import '../execution/bloc/execution_bloc.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.polycode});

  final PolyCode polycode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.polyTheme;
    final platform = polycode.platform.name.toUpperCase();

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.panelHeader,
        border: Border(
          top: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          BlocBuilder<EditorBloc, EditorState>(
            builder: (context, editorState) {
              return Text(
                'Lang: ${editorState.language.displayName}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.primaryText,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Platform: $platform',
            style: TextStyle(fontSize: 11, color: tokens.secondaryText),
          ),
          const Spacer(),
          BlocBuilder<ExecutionBloc, ExecutionBlocState>(
            builder: (context, state) {
              if (state.isRunning) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Executing...',
                      style: TextStyle(fontSize: 11, color: tokens.primaryText),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Time: ${state.duration.inMilliseconds}ms',
                    style: TextStyle(fontSize: 11, color: tokens.secondaryText),
                  ),
                  const SizedBox(width: 12),
                  if (state.exitCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: (state.exitCode == 0
                                ? tokens.success
                                : tokens.error)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: state.exitCode == 0
                              ? tokens.success
                              : tokens.error,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        'Exit: ${state.exitCode}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: state.exitCode == 0
                              ? tokens.success
                              : tokens.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
