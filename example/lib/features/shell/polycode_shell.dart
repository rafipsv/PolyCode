import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
