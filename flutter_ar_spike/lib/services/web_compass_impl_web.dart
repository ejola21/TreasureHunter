// services/web_compass.dart — 웹용 나침반 (DeviceOrientationEvent JS interop).
// flutter_compass 는 모바일 네이티브만 지원. 웹은 `window.addEventListener('deviceorientation', ...)`
// 으로 alpha(=z 축 회전)/webkitCompassHeading(iOS) 을 수신해 0~360° heading 으로 변환.
//
// 제약:
// - secure context (HTTPS / localhost) 필요. HTTP origin 에서는 이벤트 미발생.
// - iOS Safari 는 `DeviceOrientationEvent.requestPermission()` 명시 호출 필요. Android Chrome 은 자동.
// - alpha 의 0° 정의가 브라우저별로 다름 — 일반적으로 "디바이스 시작 시점의 z 축 방향"이라
//   진북 기준이 아님. iOS Safari `webkitCompassHeading` 만 진북 기준.
// - 정확도는 네이티브보다 낮음 — AR 빌보드 X 위치 보정용으로만 사용.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

class WebCompass {
  final _ctrl = StreamController<double>.broadcast();
  JSFunction? _listener;

  /// 0~360° heading 스트림 (시계방향, 진북 근사).
  Stream<double> get headingStream => _ctrl.stream;

  /// 리스너 등록 — Android Chrome 은 즉시 동작, iOS Safari 는 사전에
  /// `DeviceOrientationEvent.requestPermission()` 후 호출.
  void start() {
    _listener = ((web.Event event) {
      // DeviceOrientationEvent: alpha (z 축 0~360), beta (x 축 -180~180), gamma (y 축 -90~90)
      // iOS Safari 만 webkitCompassHeading 제공 (진북 기준).
      final e = event as web.DeviceOrientationEvent;
      final eObj = e as JSObject;
      final webkitHeading = eObj.getProperty('webkitCompassHeading'.toJS);
      double heading;
      if (webkitHeading != null && webkitHeading.isA<JSNumber>()) {
        // iOS: webkitCompassHeading 가 곧 진북 기준 시계방향 각도.
        heading = (webkitHeading as JSNumber).toDartDouble;
      } else {
        // Android: alpha 사용. alpha 는 반시계 방향이라 360 - alpha 로 시계방향 변환.
        final alpha = e.alpha ?? 0;
        heading = (360 - alpha) % 360;
      }
      _ctrl.add(heading);
    }).toJS;
    web.window.addEventListener('deviceorientation', _listener);
  }

  Future<void> stop() async {
    if (_listener != null) {
      web.window.removeEventListener('deviceorientation', _listener!);
      _listener = null;
    }
    await _ctrl.close();
  }

  /// iOS Safari 사전 권한 요청. 사용자 제스처(탭 등) 안에서 호출해야 함.
  /// Android Chrome 은 호출 불필요 — true 반환.
  static Future<bool> requestPermission() async {
    final win = web.window as JSObject;
    final cls = win.getProperty('DeviceOrientationEvent'.toJS);
    if (cls == null) return false;
    final clsObj = cls as JSObject;
    final hasRequest = clsObj.hasProperty('requestPermission'.toJS);
    if (!hasRequest.toDart) return true; // Android — 권한 함수 없음, 그냥 OK.
    final promise = clsObj.callMethod('requestPermission'.toJS) as JSPromise;
    final result = await promise.toDart;
    return result.toString() == 'granted';
  }
}
