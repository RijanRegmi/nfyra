import 'package:flutter/material.dart';

// We use Inter via system font fallback since we're offline (no network fonts).
// Fonts can be added to assets/fonts/ and referenced in pubspec if needed.

class AppTheme {
  static const _seedColor = Color(0xFF6C63FF); // vibrant indigo

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
    );
    return _base(cs).copyWith(
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    );
    return _base(cs).copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  static ThemeData _base(ColorScheme cs) {
    final textTheme = TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 57, color: cs.onSurface),
      displayMedium: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 45, color: cs.onSurface),
      headlineLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 32, color: cs.onSurface),
      headlineMedium: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 28, color: cs.onSurface),
      titleLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 22, color: cs.onSurface),
      titleMedium: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: cs.onSurface),
      bodyLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 16, color: cs.onSurface),
      bodyMedium: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 14, color: cs.onSurface),
      labelLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: cs.onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: textTheme,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cs.surfaceContainerHighest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withAlpha(128),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: cs.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
