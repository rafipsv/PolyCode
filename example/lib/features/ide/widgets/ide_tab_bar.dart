import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/polycode_theme.dart';
import '../../editor/bloc/editor_bloc.dart';
import '../bloc/ide_workspace_bloc.dart';

class IdeTabBar extends StatelessWidget {
  const IdeTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdeWorkspaceBloc, IdeState>(
      builder: (context, state) {
        return Container(
          height: 38,
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.openTabs.length,
                  itemBuilder: (context, idx) {
                    final fileName = state.openTabs[idx];
                    final isActive = fileName == state.activeFileName;

                    return InkWell(
                      onTap: () {
                        context
                            .read<IdeWorkspaceBloc>()
                            .add(SelectFileRequested(fileName));
                        final file = state.files[fileName];
                        if (file != null) {
                          context
                              .read<EditorBloc>()
                              .add(SourceChanged(file.content));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).scaffoldBackgroundColor
                              : Theme.of(context).cardColor,
                          border: Border(
                            top: BorderSide(
                              color: isActive
                                  ? PolyCodeTheme.accentColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                            right: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fileName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                context
                                    .read<IdeWorkspaceBloc>()
                                    .add(CloseTabRequested(fileName));
                              },
                              child: const Icon(Icons.close, size: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Search toggle button
              IconButton(
                icon: Icon(
                  Icons.search,
                  size: 18,
                  color: state.isSearchOpen ? PolyCodeTheme.accentColor : null,
                ),
                tooltip: 'Find in File',
                onPressed: () {
                  context
                      .read<IdeWorkspaceBloc>()
                      .add(const ToggleSearchRequested());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
