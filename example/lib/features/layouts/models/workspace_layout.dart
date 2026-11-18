import 'package:flutter/material.dart';

/// Available workspace layouts for the PolyCode Playground.
enum WorkspaceLayout {
  competitive(
    displayName: 'Competitive',
    icon: Icons.emoji_events_outlined,
    tooltip: 'Competitive Programming Workspace',
  ),
  codeBlock(
    displayName: 'Code Block',
    icon: Icons.integration_instructions_outlined,
    tooltip: 'Embeddable Snippet Card',
  ),
  ide(
    displayName: 'IDE',
    icon: Icons.dashboard_customize_outlined,
    tooltip: 'VS Code-style Multi-file IDE',
  );

  const WorkspaceLayout({
    required this.displayName,
    required this.icon,
    required this.tooltip,
  });

  final String displayName;
  final IconData icon;
  final String tooltip;
}
