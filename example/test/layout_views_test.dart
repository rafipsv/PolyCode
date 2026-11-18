import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import 'package:polycode_playground/core/theme/polycode_theme.dart';
import 'package:polycode_playground/features/competitive/bloc/competitive_bloc.dart';
import 'package:polycode_playground/features/competitive/models/problem_model.dart';
import 'package:polycode_playground/features/editor/bloc/editor_bloc.dart';
import 'package:polycode_playground/features/execution/bloc/execution_bloc.dart';
import 'package:polycode_playground/features/ide/bloc/ide_workspace_bloc.dart';
import 'package:polycode_playground/features/layouts/bloc/layout_bloc.dart';
import 'package:polycode_playground/features/layouts/models/workspace_layout.dart';
import 'package:polycode_playground/features/layouts/views/code_block_layout_view.dart';
import 'package:polycode_playground/features/layouts/views/competitive_layout_view.dart';
import 'package:polycode_playground/features/layouts/views/ide_layout_view.dart';
import 'package:polycode_playground/features/shell/polycode_shell.dart';
import 'package:polycode_playground/features/themes/bloc/theme_bloc.dart';

void main() {
  group('Phase 6 Layouts & BLoC Suite', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode(autoRegisterDefaults: false);
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('LayoutBloc switches layouts and toggles panels correctly', () async {
      final bloc = LayoutBloc();
      expect(bloc.state.activeLayout, equals(WorkspaceLayout.ide));
      expect(bloc.state.isSidebarOpen, isTrue);
      expect(bloc.state.isBottomPanelOpen, isTrue);

      bloc.add(const SwitchLayout(WorkspaceLayout.competitive));
      await pumpEventQueue();
      expect(bloc.state.activeLayout, equals(WorkspaceLayout.competitive));

      bloc.add(const SwitchLayout(WorkspaceLayout.codeBlock));
      await pumpEventQueue();
      expect(bloc.state.activeLayout, equals(WorkspaceLayout.codeBlock));

      bloc.add(const ToggleSidebar());
      await pumpEventQueue();
      expect(bloc.state.isSidebarOpen, isFalse);

      bloc.add(const ToggleBottomPanel());
      await pumpEventQueue();
      expect(bloc.state.isBottomPanelOpen, isFalse);

      bloc.add(const SetReadOnlyMode(true));
      await pumpEventQueue();
      expect(bloc.state.isReadOnly, isTrue);

      bloc.add(const ChangeEditorFontSize(2.0));
      await pumpEventQueue();
      expect(bloc.state.fontSize, equals(15.0));
    });

    test('CompetitiveBloc adds test cases and selects problems', () async {
      final bloc = CompetitiveBloc(polycode: polycode);
      expect(bloc.state.activeProblem.id, equals('sum-of-array'));
      expect(bloc.state.testCases.length, greaterThanOrEqualTo(2));

      bloc.add(
        const AddTestCaseRequested(
          input: '2\n10 20',
          expectedOutput: '30',
        ),
      );
      await pumpEventQueue();
      expect(bloc.state.testCases.length, equals(4));
      expect(bloc.state.testCases.last.input, equals('2\n10 20'));

      bloc.add(SelectProblemRequested(ProblemModel.sampleProblems[1]));
      await pumpEventQueue();
      expect(bloc.state.activeProblem.id, equals('reverse-words'));
    });

    test('IdeWorkspaceBloc manages files, tabs, and search', () async {
      final bloc = IdeWorkspaceBloc(initialLanguage: PolyLanguage.python);
      expect(bloc.state.files.containsKey('main.py'), isTrue);
      expect(bloc.state.openTabs.contains('main.py'), isTrue);

      // Create new file
      bloc.add(const CreateFileRequested('test.py', content: 'print(42)'));
      await pumpEventQueue();
      expect(bloc.state.files.containsKey('test.py'), isTrue);
      expect(bloc.state.activeFileName, equals('test.py'));
      expect(bloc.state.openTabs.contains('test.py'), isTrue);

      // Close tab
      bloc.add(const CloseTabRequested('test.py'));
      await pumpEventQueue();
      expect(bloc.state.openTabs.contains('test.py'), isFalse);

      // Select file
      bloc.add(const SelectFileRequested('main.py'));
      await pumpEventQueue();
      expect(bloc.state.activeFileName, equals('main.py'));

      // Delete file
      bloc.add(const DeleteFileRequested('test.py'));
      await pumpEventQueue();
      expect(bloc.state.files.containsKey('test.py'), isFalse);

      // Search query
      bloc.add(const ToggleSearchRequested());
      await pumpEventQueue();
      expect(bloc.state.isSearchOpen, isTrue);
      bloc.add(const SearchQueryChanged('print'));
      await pumpEventQueue();
      expect(bloc.state.searchQuery, equals('print'));
    });

    Widget createTestApp({required WorkspaceLayout initialLayout}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => LayoutBloc(initialLayout: initialLayout)),
          BlocProvider(create: (_) => EditorBloc()),
          BlocProvider(create: (_) => ExecutionBloc(polycode: polycode)),
          BlocProvider(create: (_) => CompetitiveBloc(polycode: polycode)),
          BlocProvider(create: (_) => IdeWorkspaceBloc()),
        ],
        child: MaterialApp(
          theme: PolyCodeTheme.darkTheme,
          home: PolyCodeShell(polycode: polycode),
        ),
      );
    }

    testWidgets('CompetitiveLayoutView renders problem and test runner',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(initialLayout: WorkspaceLayout.competitive),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompetitiveLayoutView), findsOneWidget);
      expect(find.textContaining('Sum of Array Elements'), findsOneWidget);
      expect(find.textContaining('Run Test Cases'), findsOneWidget);
      expect(find.textContaining('Constraints'), findsOneWidget);
    });

    testWidgets('CodeBlockLayoutView renders snippet card and output toggle',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(initialLayout: WorkspaceLayout.codeBlock),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CodeBlockLayoutView), findsOneWidget);
      expect(find.text('Run'), findsWidgets);
      expect(find.text('Output'), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('IdeLayoutView renders file explorer, tabs, and bottom panel',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(initialLayout: WorkspaceLayout.ide),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IdeLayoutView), findsOneWidget);
      expect(find.text('EXPLORER'), findsOneWidget);
      expect(find.text('OUTPUT / TERMINAL'), findsOneWidget);
      expect(find.text('PROBLEMS'), findsOneWidget);
      expect(find.text('main.py'), findsWidgets);
    });

    testWidgets('Switching layouts preserves source code and language',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final layoutBloc = LayoutBloc(initialLayout: WorkspaceLayout.ide);
      final editorBloc = EditorBloc(initialLanguage: PolyLanguage.python);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeBloc()),
            BlocProvider.value(value: layoutBloc),
            BlocProvider.value(value: editorBloc),
            BlocProvider(create: (_) => ExecutionBloc(polycode: polycode)),
            BlocProvider(create: (_) => CompetitiveBloc(polycode: polycode)),
            BlocProvider(create: (_) => IdeWorkspaceBloc()),
          ],
          child: MaterialApp(
            theme: PolyCodeTheme.darkTheme,
            home: PolyCodeShell(polycode: polycode),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modify source
      const customCode = '# Custom Preserved Code Snippet\nx = 999\n';
      editorBloc.add(const SourceChanged(customCode));
      await tester.pumpAndSettle();

      // Switch to Code Block view
      layoutBloc.add(const SwitchLayout(WorkspaceLayout.codeBlock));
      await tester.pumpAndSettle();

      expect(find.byType(CodeBlockLayoutView), findsOneWidget);
      expect(editorBloc.state.source, equals(customCode));

      // Switch to Competitive view
      layoutBloc.add(const SwitchLayout(WorkspaceLayout.competitive));
      await tester.pumpAndSettle();

      expect(find.byType(CompetitiveLayoutView), findsOneWidget);
      expect(editorBloc.state.source, equals(customCode));
    });
  });
}
