import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';
import 'package:polycode_playground/core/theme/polycode_theme.dart';
import 'package:polycode_playground/features/editor/bloc/editor_bloc.dart';
import 'package:polycode_playground/features/execution/bloc/execution_bloc.dart';
import 'package:polycode_playground/features/shell/polycode_shell.dart';
import 'package:polycode_playground/features/themes/bloc/theme_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('Playground MVP Widgets & BLoC', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode(autoRegisterDefaults: false);
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('ThemeBloc toggles between dark and light themes', () {
      final bloc = ThemeBloc();
      expect(bloc.state.mode, equals(ThemeMode.dark));

      bloc.add(const ToggleThemeRequested());
      expect(
          bloc.stream,
          emits(isA<ThemeState>()
              .having((s) => s.mode, 'mode', ThemeMode.light)));
    });

    test('EditorBloc loads language templates and updates source', () {
      final bloc = EditorBloc(initialLanguage: PolyLanguage.python);
      expect(bloc.state.source, contains('PolyCode Python'));

      bloc.add(const LanguageChanged(PolyLanguage.javascript));
      expect(
        bloc.stream,
        emits(isA<EditorState>()
            .having((s) => s.language, 'language', PolyLanguage.javascript)),
      );
    });

    testWidgets('PolyCodeShell renders editor and console layout',
        (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeBloc()),
            BlocProvider(create: (_) => EditorBloc()),
            BlocProvider(create: (_) => ExecutionBloc(polycode: polycode)),
          ],
          child: MaterialApp(
            theme: PolyCodeTheme.darkTheme,
            home: PolyCodeShell(polycode: polycode),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('PolyCode'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
      expect(find.textContaining('Output'), findsOneWidget);
      expect(find.textContaining('Input (stdin)'), findsOneWidget);
    });
  });
}
