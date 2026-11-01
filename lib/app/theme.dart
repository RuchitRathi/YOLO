import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class YoloColors {
  static const yellow = Color(0xFFFFD43B);
  static const red = Color(0xFFF04438);
  static const blue = Color(0xFF2878FF);
  static const background = Color(0xFFFFF9E8);
  static const ink = Color(0xFF202020);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: YoloColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YoloColors.yellow,
        primary: YoloColors.yellow,
        secondary: YoloColors.red,
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
