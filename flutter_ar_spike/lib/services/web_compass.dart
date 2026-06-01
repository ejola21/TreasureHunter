// services/web_compass.dart — 웹용 나침반 entry. 조건부 import 로 플랫폼별 구현 선택.
// - 웹: web_compass_impl_web.dart (DeviceOrientationEvent JS interop)
// - 비-웹 (Android/iOS 네이티브): web_compass_impl_stub.dart (no-op)
//
// 비-웹에서는 이 클래스가 호출되지 않음 (ar_play.dart 가 kIsWeb 가드 안에서만 사용).
// stub 은 컴파일을 위해 필요할 뿐.
export 'web_compass_impl_stub.dart'
    if (dart.library.js_interop) 'web_compass_impl_web.dart';
