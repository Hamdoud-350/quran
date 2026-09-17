import 'package:flutter/material.dart';

/// Material 3 theme with Material You dynamic colors + full dark/light.
/// Use with: MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, ...)
class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6B4F), // emerald (Quran green)
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6B4F),
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
      );
}
