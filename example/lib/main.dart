import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:polycode/polycode.dart';
import 'core/theme/polycode_theme.dart';
import 'features/competitive/bloc/competitive_bloc.dart';
import 'features/editor/bloc/editor_bloc.dart';
import 'features/execution/bloc/execution_bloc.dart';
import 'features/ide/bloc/ide_workspace_bloc.dart';
import 'features/layouts/bloc/layout_bloc.dart';
import 'features/shell/polycode_shell.dart';
import 'features/themes/bloc/theme_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PolyCodeApp());
}

class PolyCodeApp extends StatefulWidget {
  const PolyCodeApp({super.key});

  @override
  State<PolyCodeApp> createState() => _PolyCodeAppState();
}

class _PolyCodeAppState extends State<PolyCodeApp> {
  late final PolyCode _polycode;

  @override
  void initState() {
    super.initState();
    _polycode = PolyCode();
  }

  @override
  void dispose() {
    _polycode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => LayoutBloc()),
        BlocProvider(create: (_) => EditorBloc()),
        BlocProvider(create: (_) => ExecutionBloc(polycode: _polycode)),
        BlocProvider(create: (_) => CompetitiveBloc(polycode: _polycode)),
        BlocProvider(create: (_) => IdeWorkspaceBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'PolyCode Playground',
            debugShowCheckedModeBanner: false,
            theme: PolyCodeTheme.lightTheme,
            darkTheme: PolyCodeTheme.darkTheme,
            themeMode: themeState.mode,
            home: PolyCodeShell(polycode: _polycode),
          );
        },
      ),
    );
  }
}
