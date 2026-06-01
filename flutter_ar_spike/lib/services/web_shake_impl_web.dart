// services/web_shake.dart — 웹용 흔들기 감지 (DeviceMotionEvent JS interop).
// sensors_plus 가 웹 미지원이라, 가속도 데이터는 브라우저 표준 API 로 직접 읽음.
// AR/미니게임 의 흔들기 임계치 (1.4G ≈ 14.0 m/s²) 동일 적용.
//
// 제약:
// - secure context (HTTPS / localhost) 필요. HTTP origin 에서는 이벤트 미발생.
// - iOS Safari 는 `DeviceMotionEvent.requestPermission()` 명시 호출 필요. Android Chrome 자동.
// - `acceleration` (중력 제거) 가 없는 브라우저는 `accelerationIncludingGravity` 폴백 사용
//   (이때는 정지 상태 ≈ 9.8 임을 고려해 임계치를 더 높게 잡아야 정확).
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'package:web/web.dart' as web;

class WebShake {
  final _ctrl = StreamController<double>.broadcast();
  JSFunction? _listener;

  /// 가속도 크기(m/s²) 스트림 — 호출자가 임계치 비교.
  Stream<double> get magnitudeStream => _ctrl.stream;

  void start() {
    _listener = ((web.Event event) {
      final e = event as web.DeviceMotionEvent;
      final eObj = e as JSObject;
      // 우선 `acceleration` (중력 제거) 시도, 없으면 `accelerationIncludingGravity` 폴백.
      JSObject? accel = eObj.getProperty('acceleration'.toJS) as JSObject?;
      bool gravityIncluded = false;
      if (accel == null ||
          accel.getProperty('x'.toJS) == null) {
        accel = eObj.getProperty('accelerationIncludingGravity'.toJS) as JSObject?;
        gravityIncluded = true;
      }
      if (accel == null) return;
      double readNum(String key) {
        final v = accel!.getProperty(key.toJS);
        if (v != null && v.isA<JSNumber>()) return (v as JSNumber).toDartDouble;
        return 0;
      }
      final x = readNum('x'), y = readNum('y'), z = readNum('z');
      var mag = math.sqrt(x * x + y * y + z * z);
      // 중력 포함 데이터면 정지 시 ≈ 9.8 을 빼서 동등하게 비교 가능하도록 보정.
      if (gravityIncluded) mag = (mag - 9.8).abs();
      _ctrl.add(mag);
    }).toJS;
    web.window.addEventListener('devicemotion', _listener);
  }

  Future<void> stop() async {
    if (_listener != null) {
      web.window.removeEventListener('devicemotion', _listener!);
      _listener = null;
    }
    await _ctrl.close();
  }

  /// iOS Safari 사전 권한. Android Chrome 은 호출 불필요 — true.
  /// 사용자 제스처(탭) 안에서 호출해야 권한 다이얼로그 표시됨.
  static Future<bool> requestPermission() async {
    final win = web.window as JSObject;
    final cls = win.getProperty('DeviceMotionEvent'.toJS);
    if (cls == null) return false;
    final clsObj = cls as JSObject;
    final hasRequest = clsObj.hasProperty('requestPermission'.toJS);
    if (!hasRequest.toDart) return true;
    final promise = clsObj.callMethod('requestPermission'.toJS) as JSPromise;
    final result = await promise.toDart;
    return result.toString() == 'granted';
  }
}
