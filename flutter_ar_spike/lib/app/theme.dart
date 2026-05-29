// app/theme.dart — DuoTokens 기반 앱 테마.
import 'package:flutter/material.dart';
import '../design_system/duo_tokens.dart';

ThemeData buildPlaySpotTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: DuoColors.green500,
    primary: DuoColors.green500,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DuoColors.snow,
    // Jalnan2 미등록 시 null → 시스템 폰트 폴백 (P0-4 에서 등록).
    fontFamily: DuoFonts.display,
    appBarTheme: const AppBarTheme(
      backgroundColor: DuoColors.snow,
      foregroundColor: DuoColors.eel2,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
