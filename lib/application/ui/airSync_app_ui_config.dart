// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AirSyncAppUiConfig {
  AirSyncAppUiConfig._();

  static String get tittle => "Air Sync";

  static ThemeData get theme {
    const bg = Color(0xFF0F1216);
    const surface = Color(0xFF1A1F24);
    const primary = Color(0xFF00B686);
    const secondary = Color(0xFFFFA15C);
    const textMain = Color(0xFFF2F5F7);
    const textSub = Color(0xFFA9B2B9);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
      primary: primary,
      secondary: secondary,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: textMain,
      error: const Color(0xFFE74C3C),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textMain),
        bodyMedium: TextStyle(fontSize: 15, color: textMain, height: 1.35),
        bodySmall: TextStyle(fontSize: 13, color: textSub, height: 1.35),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x15FFFFFF)),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x15FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x15FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textSub),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textMain,
        textColor: textMain,
        dense: true,
        horizontalTitleGap: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerColor: const Color(0x15FFFFFF),
    );
  }
}
