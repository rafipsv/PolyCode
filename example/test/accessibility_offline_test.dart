import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';
import 'package:polycode_playground/core/theme/polycode_theme.dart';
import 'package:polycode_playground/core/theme/polycode_theme_tokens.dart';
import 'package:polycode_playground/features/competitive/bloc/competitive_bloc.dart';
import 'package:polycode_playground/features/editor/bloc/editor_bloc.dart';
import 'package:polycode_playground/features/execution/bloc/execution_bloc.dart';
import 'package:polycode_playground/features/ide/bloc/ide_workspace_bloc.dart';
import 'package:polycode_playground/features/layouts/bloc/layout_bloc.dart';
import 'package:polycode_playground/features/shell/polycode_shell.dart';
import 'package:polycode_playground/features/shell/status_bar.dart';
import 'package:polycode_playground/features/themes/bloc/theme_bloc.dart';

void main() {
  group('Phase 11: Accessibility & Offline Tests', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    Widget buildTestApp({
      PolyCodeThemeTokens? tokens,
    }) {
      final activeTokens = tokens ?? PolyCodeThemeTokens.dark;
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => LayoutBloc()),
          BlocProvider(create: (_) => EditorBloc()),
          BlocProvider(create: (_) => ExecutionBloc(polycode: polycode)),
          BlocProvider(create: (_) => CompetitiveBloc(polycode: polycode)),
          BlocProvider(create: (_) => IdeWorkspaceBloc()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [activeTokens],
          ),
          home: PolyCodeShell(polycode: polycode),
        ),
      );
    }

    testWidgets('StatusBar displays Local-First offline badge and semantics',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(StatusBar), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.textContaining('Lang:'), findsOneWidget);
      expect(find.textContaining('Platform:'), findsOneWidget);

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Local-First Offline Engine Sandbox'),
        findsOneWidget,
      );
    });

    testWidgets('PolyCodeShell provides accessible interactive semantics',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            (w.properties.label?.contains('Run Code') ?? false)),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Language Selector'),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Workspace Layout Selector'),
        findsOneWidget,
      );
    });

    testWidgets('High Contrast A11y Theme ensures maximum contrast',
        (tester) async {
      const tokens = PolyCodeThemeTokens.highContrast;
      expect(tokens.appBackground, equals(Colors.black));
      expect(tokens.primaryText, equals(Colors.white));
      expect(tokens.border, equals(Colors.white));

      await tester.pumpWidget(buildTestApp(tokens: tokens));
      await tester.pumpAndSettle();

      expect(find.byType(PolyCodeShell), findsOneWidget);
    });
  });
}
