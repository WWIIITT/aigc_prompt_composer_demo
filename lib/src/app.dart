import 'package:flutter/material.dart';

import 'workbench_screen.dart';

abstract final class WorkbenchColors {
  static const ink = Color(0xFF0B132B);
  static const cyan = Color(0xFF087F75);
  static const cyanBright = Color(0xFF38D9C5);
  static const orange = Color(0xFFFFB454);
  static const paper = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFD9E1EA);
  static const muted = Color(0xFF58657A);
  static const danger = Color(0xFFD94B5B);
}

class PromptWorkbenchApp extends StatelessWidget {
  const PromptWorkbenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: WorkbenchColors.cyan,
          brightness: Brightness.light,
        ).copyWith(
          primary: WorkbenchColors.cyan,
          onPrimary: Colors.white,
          secondary: WorkbenchColors.orange,
          onSecondary: WorkbenchColors.ink,
          error: WorkbenchColors.danger,
          surface: WorkbenchColors.surface,
          onSurface: WorkbenchColors.ink,
          outline: WorkbenchColors.line,
        );

    return MaterialApp(
      title: 'Prompt Workbench',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: WorkbenchColors.paper,
        fontFamily: 'sans-serif',
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: WorkbenchColors.ink,
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineSmall: TextStyle(
            color: WorkbenchColors.ink,
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: WorkbenchColors.ink,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(
            color: WorkbenchColors.ink,
            fontSize: 14,
            height: 1.45,
          ),
          labelMedium: TextStyle(
            color: WorkbenchColors.muted,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.45,
          ),
        ),
        cardTheme: const CardThemeData(
          color: WorkbenchColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: WorkbenchColors.line),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: WorkbenchColors.paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: WorkbenchColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: WorkbenchColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: WorkbenchColors.cyan, width: 2),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : WorkbenchColors.muted,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? WorkbenchColors.cyan
                : WorkbenchColors.line,
          ),
        ),
      ),
      home: const WorkbenchScreen(),
    );
  }
}
