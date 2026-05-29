// compass_service_web.dart
// Web 나침반(heading) — DeviceOrientationEvent JS interop.
//   - iOS Safari: event.webkitCompassHeading (0~360, 진북 기준)
//   - Android Chrome: event.alpha (absolute 아니면 360 - alpha 보정)
//   - iOS 13+: DeviceOrientationEvent.requestPermission() 를 사용자 제스처 안에서 호출
//   - Desktop: 이벤트 없음 → emitMock 으로 슬라이더 값 주입
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

import 'heading_sample.dart';

/// deviceorientation 이벤트의 표준/비표준 프로퍼티 접근용.
extension type _OrientationEvent(JSObject _) implements JSObject {
  external JSNumber? get webkitCompassHeading; // iOS Safari
  external JSNumber? get alpha; // 표준
  external JSBoolean? get absolute;
}

class CompassService {
  final _controller = StreamController<HeadingSample>.broadcast();
  Stream<HeadingSample> get stream => _controller.stream;

  JSFunction? _listener;
  bool _subscribed = false;

  // 원형 EMA 스무딩 (plan §8: webkitCompassHeading 노이즈 완화). mock 은 스무딩 안 함.
  double? _smoothed;
  static const double _alpha = 0.2;

  /// 구독 시작. 반환 false → heading 미지원(데스크톱) 이므로 mock 사용.
  /// iOS 13+ 권한 요청은 반드시 사용자 제스처 콜스택 안에서 호출해야 한다.
  Future<bool> start() async {
    final ctor = web.window.getProperty<JSAny?>('DeviceOrientationEvent'.toJS);
    if (ctor.isUndefinedOrNull) return false;
    final ctorObj = ctor as JSObject;

    // iOS 13+ : requestPermission() 정적 메서드 존재 시 권한 요청.
    if (ctorObj.has('requestPermission')) {
      try {
        final promise =
            ctorObj.callMethod<JSPromise<JSString>>('requestPermission'.toJS);
        final result = await promise.toDart;
        if (result.toDart != 'granted') return false;
      } catch (_) {
        return false;
      }
    }
    _subscribe();
    return true;
  }

  void _subscribe() {
    if (_subscribed) return;
    _subscribed = true;
    _listener = ((web.Event e) {
      final oe = _OrientationEvent(e as JSObject);
      final webkit = oe.webkitCompassHeading?.toDartDouble;
      if (webkit != null && !webkit.isNaN) {
        _controller.add(HeadingSample(_smooth(_wrap360(webkit)), 'webkitCompass'));
        return;
      }
      final alpha = oe.alpha?.toDartDouble;
      if (alpha != null && !alpha.isNaN) {
        final absolute = oe.absolute?.toDart ?? false;
        final h = absolute ? alpha : (360 - alpha);
        _controller.add(HeadingSample(_smooth(_wrap360(h)), 'alpha'));
      }
    }).toJS;
    web.window.addEventListener('deviceorientation', _listener);
  }

  /// 데스크톱 mock — heading 슬라이더 값 주입.
  void emitMock(double heading) {
    _controller.add(HeadingSample(_wrap360(heading), 'mock'));
  }

  double _wrap360(double h) => (h % 360 + 360) % 360;

  /// 원형 EMA — 0/360 경계에서 튀지 않도록 최단각(-180~180) 델타로 보간.
  double _smooth(double raw) {
    final prev = _smoothed;
    if (prev == null) {
      _smoothed = raw;
      return raw;
    }
    var diff = (raw - prev) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    final next = _wrap360(prev + _alpha * diff);
    _smoothed = next;
    return next;
  }

  void dispose() {
    final l = _listener;
    if (l != null) web.window.removeEventListener('deviceorientation', l);
    _controller.close();
  }
}
