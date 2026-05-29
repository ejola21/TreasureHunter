// design_system/duo_tokens.dart
// PlaySpot/Views/DesignSystem/DuoTokens.swift 색/반경 토큰 이식 (Duolingo 풍).
import 'package:flutter/widgets.dart';

/// Duolingo 풍 색 팔레트 (DuoTokens.swift 와 동일 hex).
abstract final class DuoColors {
  // Brand greens
  static const green100 = Color(0xFFD7FFB8);
  static const green200 = Color(0xFFB7FF80);
  static const green300 = Color(0xFF93E85C);
  static const green400 = Color(0xFF8EE000);
  static const green500 = Color(0xFF58CC02); // PRIMARY
  static const green550 = Color(0xFF5ACD05);
  static const green700 = Color(0xFF5AA703); // primary button shadow
  static const green750 = Color(0xFF48A502);
  static const green800 = Color(0xFF43A601);
  static const green900 = Color(0xFF375B0A);

  // Macaw (blue)
  static const macaw = Color(0xFF1CB0F6);
  static const macawDeep = Color(0xFF0084C2);
  static const macawBg = Color(0xFFD2EFFD);
  static const macawBorder = Color(0xFF77D0FA);
  static const macawNavBg = Color(0xFFE1F4FF);
  static const macawNavBorder = Color(0xFF91D7F6);

  // Cardinal (red)
  static const cardinal = Color(0xFFFF4B4B);
  static const cardinalDeep = Color(0xFFEA2B2B);
  static const cardinalBg = Color(0xFFFFDFE0);

  // Bee (yellow)
  static const bee = Color(0xFFFFC800);
  static const beeDeep = Color(0xFFE6A900);
  static const beeBg = Color(0xFFFFF4CB);

  // Fox (orange)
  static const fox = Color(0xFFFF9600);
  static const foxDeep = Color(0xFFE08600);
  static const foxBg = Color(0xFFFFE7CE);

  // Beetle (purple)
  static const beetle = Color(0xFFCE82FF);
  static const beetleDeep = Color(0xFF8C39C8);

  // Humpback (deep blue)
  static const humpback = Color(0xFF2B70C9);

  // Neutrals
  static const snow = Color(0xFFF7F7F7);
  static const polar = Color(0xFFF0F0F0);
  static const swan = Color(0xFFE5E5E5);
  static const swan2 = Color(0xFFEBEBEB);
  static const hare = Color(0xFFAFAFAF);
  static const wolf = Color(0xFF777777);
  static const wolf2 = Color(0xFF4B4B4B);
  static const eel = Color(0xFF3C3C3C);
  static const eel2 = Color(0xFF2D3339);
}

/// 모서리 반경 (DuoRadius).
abstract final class DuoRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

/// 폰트 패밀리. Jalnan2(디스플레이) 미등록 시 null → 시스템 폴백.
abstract final class DuoFonts {
  static const display = 'Jalnan2'; // pubspec fonts 등록명 (P0-4)
}
