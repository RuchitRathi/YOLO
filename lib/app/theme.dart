import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class YoloColors {
  // Soft blush, coral, mint and sage inspired by the supplied UI palette.
  static const yellow = Color(0xFFF2C5B6);
  static const red = Color(0xFFA75C64);
  static const blue = Color(0xFFB8D9CE);
  static const mint = Color(0xFFCBE9DE);
  static const sage = Color(0xFF9FB9AC);
  static const mauve = Color(0xFF907572);
  static const background = Color(0xFFF9E7E3);
  static const ink = Color(0xFF403439);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: YoloColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YoloColors.red,
        primary: YoloColors.red,
        secondary: YoloColors.sage,
        tertiary: YoloColors.blue,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          color: YoloColors.ink,
          letterSpacing: -2,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          color: YoloColors.ink,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: YoloColors.ink,
        ),
        bodyLarge: TextStyle(color: YoloColors.ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: YoloColors.background,
        foregroundColor: YoloColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: YoloColors.ink.withValues(alpha: .16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: YoloColors.ink.withValues(alpha: .16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: YoloColors.red, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: YoloColors.mint,
        side: BorderSide(color: YoloColors.ink.withValues(alpha: .12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle:
            const TextStyle(color: YoloColors.ink, fontWeight: FontWeight.w700),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
