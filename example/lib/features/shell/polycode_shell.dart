import 'package:flutter/material.dart';
import 'package:polycode/polycode.dart';
import '../editor/widgets/code_editor_panel.dart';
import '../execution/widgets/console_panel.dart';
import 'polycode_app_bar.dart';
import 'status_bar.dart';

class PolyCodeShell extends StatelessWidget {
  const PolyCodeShell({super.key, required this.polycode});

  final PolyCode polycode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PolyCodeAppBar(polycode: polycode),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;

          if (isDesktop) {
            return const Row(
              children: [
                Expanded(flex: 3, child: CodeEditorPanel()),
                VerticalDivider(width: 1),
                Expanded(flex: 2, child: ConsolePanel()),
              ],
            );
          }

          return const Column(
            children: [
              Expanded(flex: 3, child: CodeEditorPanel()),
              Divider(height: 1),
              Expanded(flex: 2, child: ConsolePanel()),
            ],
          );
        },
      ),
      bottomNavigationBar: StatusBar(polycode: polycode),
    );
  }
}
