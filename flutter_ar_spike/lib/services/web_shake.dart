// services/web_shake.dart — 웹용 흔들기 entry. 조건부 import 로 플랫폼별 구현 선택.
// - 웹: web_shake_impl_web.dart (DeviceMotionEvent JS interop)
// - 비-웹 (Android/iOS 네이티브): web_shake_impl_stub.dart (no-op)
//
// 비-웹에서는 호출되지 않음 (ar_play.dart / minigame_view.dart 가 kIsWeb 가드 안에서만 사용).
export 'web_shake_impl_stub.dart'
    if (dart.library.js_interop) 'web_shake_impl_web.dart';
