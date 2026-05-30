// services/haptic_service.dart — HapticService.swift 이식.
// 추상 [HapticService] + 실 구현 [RealHapticService] (Flutter HapticFeedback) + [FakeHapticService].
//
// SwiftUI 매핑:
//   vibrate(): UIImpactFeedbackGenerator(.heavy) — 지뢰 폭발, 팝업 OK
//   success(): UINotificationFeedbackGenerator(.success) — 팝업 onAppear
//   light():   UIImpactFeedbackGenerator(.light) — UI 터치
import 'package:flutter/services.dart';

enum HapticKind { vibrate, success, light }

abstract class HapticService {
  factory HapticService() = RealHapticService;
  void vibrate();
  void success();
  void light();
}

class RealHapticService implements HapticService {
  @override
  void vibrate() => HapticFeedback.heavyImpact();
  @override
  void success() => HapticFeedback.heavyImpact(); // Flutter 는 notification.success 가 없어 heavy 로 대체
  @override
  void light() => HapticFeedback.selectionClick();
}

/// 테스트용 fake — 호출 순서 기록.
class FakeHapticService implements HapticService {
  final calls = <HapticKind>[];
  @override
  void vibrate() => calls.add(HapticKind.vibrate);
  @override
  void success() => calls.add(HapticKind.success);
  @override
  void light() => calls.add(HapticKind.light);
  void clear() => calls.clear();
}
