// Path: lib/constants/app_themes.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0E5A38),
      scaffoldBackgroundColor: const Color(0xFFF5F0E6), // Parchment light bg

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0E5A38),
        brightness: Brightness.light,
        primary: const Color(0xFF0E5A38),
        secondary: const Color(0xFF9B7520),
        surface: Colors.white,
        background: const Color(0xFFF5F0E6),
        error: const Color(0xFFD05050),
      ),

      // Page Transitions Animation
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ... (أبقِ باقي خصائص الـ lightTheme كما كتبتها أنت في الكود السابق)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C2B1F),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C2B1F),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0E5A38),
      scaffoldBackgroundColor: const Color(0xFF071A14), // Deep Forest

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0E5A38),
        brightness: Brightness.dark,
        primary: const Color(0xFFC4973A), // Gold as primary in dark mode
        secondary: const Color(0xFF0E5A38),
        surface: const Color(0xFF0C1E16), // Dark Card Bg
        background: const Color(0xFF071A14),
        error: const Color(0xFFD05050),
      ),

      // Page Transitions Animation
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF0E6C8), // Parchment
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF0E6C8),
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF0C1E16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0x33C4973A), // Gold Border
            width: 1,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Amiri', color: Color(0xFFF0E6C8)),
        bodyLarge: TextStyle(fontFamily: 'Tajawal', color: Color(0xFFF0E6C8)),
        bodyMedium: TextStyle(fontFamily: 'Tajawal', color: Color(0x99F0E6C8)),
      ),
    );
  }
}
