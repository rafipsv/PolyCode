import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import 'package:polycode_playground/core/preferences/preferences_storage_stub.dart';
import 'package:polycode_playground/core/theme/polycode_theme.dart';
import 'package:polycode_playground/features/competitive/bloc/competitive_bloc.dart';
import 'package:polycode_playground/features/editor/bloc/editor_bloc.dart';
import 'package:polycode_playground/features/editor/widgets/syntax_highlighter_controller.dart';
import 'package:polycode_playground/features/execution/bloc/execution_bloc.dart';
import 'package:polycode_playground/features/ide/bloc/ide_workspace_bloc.dart';
import 'package:polycode_playground/features/layouts/bloc/layout_bloc.dart';
import 'package:polycode_playground/features/layouts/models/workspace_layout.dart';
import 'package:polycode_playground/features/shell/polycode_shell.dart';
import 'package:polycode_playground/features/themes/bloc/theme_bloc.dart';

void main() {
  group('Phase 7 Theme System & Preferences Tests', () {
    late PolyCode polycode;
    late InMemoryPreferencesStorage mockStorage;

    setUp(() {
      polycode = PolyCode(autoRegisterDefaults: false);
      mockStorage = InMemoryPreferencesStorage();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('PreferencesStorage correctly saves and retrieves values', () async {
      await mockStorage.setString('test_key', 'test_val');
      await mockStorage.setBool('bool_key', true);
      await mockStorage.setDouble('double_key', 16.5);

      expect(await mockStorage.getString('test_key'), equals('test_val'));
      expect(await mockStorage.getBool('bool_key'), isTrue);
      expect(await mockStorage.getDouble('double_key'), equals(16.5));

      await mockStorage.remove('test_key');
      expect(await mockStorage.getString('test_key'), isNull);

      await mockStorage.clear();
      expect(await mockStorage.getBool('bool_key'), isNull);
    });

    test('ThemeBloc toggles, sets presets, and persists choices', () async {
      final bloc = ThemeBloc(storage: mockStorage);
      await pumpEventQueue();

      expect(bloc.state.mode, equals(ThemeMode.dark));
      expect(bloc.state.preset, equals(PolyCodeThemePreset.dark));

      // Toggle to light
      bloc.add(const ToggleThemeRequested());
      await pumpEventQueue();
      expect(bloc.state.mode, equals(ThemeMode.light));
      expect(await mockStorage.getString('polycode_theme_mode'),
          equals(ThemeMode.light.name));

      // Set High Contrast preset
      bloc.add(const SetThemePresetRequested(PolyCodeThemePreset.highContrast));
      await pumpEventQueue();
      expect(bloc.state.preset, equals(PolyCodeThemePreset.highContrast));
      expect(bloc.state.isHighContrast, isTrue);
      expect(bloc.state.darkTheme.scaffoldBackgroundColor,
          equals(PolyCodeThemeTokens.hcAppBackground));

      // Verify persistence reload
      final reloadedBloc = ThemeBloc(storage: mockStorage);
      await pumpEventQueue();
      expect(
          reloadedBloc.state.preset, equals(PolyCodeThemePreset.highContrast));
    });

    test(
        'PolyCodeThemeTokens dark, light, and highContrast tokens are distinct',
        () {
      const darkTokens = PolyCodeThemeTokens.dark;
      const lightTokens = PolyCodeThemeTokens.light;
      const hcTokens = PolyCodeThemeTokens.highContrast;

      expect(
          darkTokens.appBackground, isNot(equals(lightTokens.appBackground)));
      expect(hcTokens.appBackground, equals(const Color(0xFF000000)));
      expect(hcTokens.border, equals(const Color(0xFFFFFFFF)));

      // Interpolation / lerp test
      final lerped = darkTokens.lerp(lightTokens, 0.5) as PolyCodeThemeTokens;
      expect(lerped.appBackground, isNotNull);
    });

    testWidgets('SyntaxHighlighterEditingController builds formatted spans',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final controller = SyntaxHighlighterEditingController(
                text: 'def solve():\n  # comment\n  x = 42\n  return "ok"',
                language: PolyLanguage.python,
                tokens: PolyCodeThemeTokens.dark,
              );

              final span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 14),
                withComposing: false,
              );

              expect(span.children, isNotNull);
              expect(span.children!.length, greaterThan(3));

              controller.updateThemeAndLanguage(
                  PolyLanguage.javascript, PolyCodeThemeTokens.light);
              expect(controller.language, equals(PolyLanguage.javascript));
              expect(controller.tokens, equals(PolyCodeThemeTokens.light));

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    test('LayoutBloc persists layout and font preferences', () async {
      final layoutBloc = LayoutBloc(storage: mockStorage);
      await pumpEventQueue();

      layoutBloc.add(const SwitchLayout(WorkspaceLayout.codeBlock));
      layoutBloc.add(const ChangeEditorFontSize(3.0));
      layoutBloc.add(const SetReadOnlyMode(true));
      await pumpEventQueue();

      expect(
          await mockStorage.getString('polycode_layout'), equals('codeBlock'));
      expect(await mockStorage.getDouble('polycode_font_size'), equals(16.0));
      expect(await mockStorage.getBool('polycode_read_only'), isTrue);

      // Reload in fresh bloc
      final reloaded = LayoutBloc(storage: mockStorage);
      await pumpEventQueue();
      expect(reloaded.state.activeLayout, equals(WorkspaceLayout.codeBlock));
      expect(reloaded.state.fontSize, equals(16.0));
      expect(reloaded.state.isReadOnly, isTrue);
    });

    testWidgets('PolyCodeShell renders smoothly in Dark theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeBloc()),
            BlocProvider(create: (_) => LayoutBloc()),
            BlocProvider(create: (_) => EditorBloc()),
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
      expect(find.byType(PolyCodeShell), findsOneWidget);
    });

    testWidgets('PolyCodeShell renders smoothly in Light theme',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ThemeBloc(
                initialMode: ThemeMode.light,
                initialPreset: PolyCodeThemePreset.light,
              ),
            ),
            BlocProvider(create: (_) => LayoutBloc()),
            BlocProvider(create: (_) => EditorBloc()),
            BlocProvider(create: (_) => ExecutionBloc(polycode: polycode)),
            BlocProvider(create: (_) => CompetitiveBloc(polycode: polycode)),
            BlocProvider(create: (_) => IdeWorkspaceBloc()),
          ],
          child: MaterialApp(
            theme: PolyCodeTheme.lightTheme,
            home: PolyCodeShell(polycode: polycode),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PolyCodeShell), findsOneWidget);
    });

    testWidgets('PolyCodeShell renders smoothly in High Contrast theme',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ThemeBloc(
                initialPreset: PolyCodeThemePreset.highContrast,
              ),
            ),
            BlocProvider(create: (_) => LayoutBloc()),
            BlocProvider(create: (_) => EditorBloc()),
            BlocProvider(create: (_) => ExecutionBloc(polycode: polycode)),
            BlocProvider(create: (_) => CompetitiveBloc(polycode: polycode)),
            BlocProvider(create: (_) => IdeWorkspaceBloc()),
          ],
          child: MaterialApp(
            theme: PolyCodeTheme.highContrastTheme,
            home: PolyCodeShell(polycode: polycode),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PolyCodeShell), findsOneWidget);
    });
  });
}
