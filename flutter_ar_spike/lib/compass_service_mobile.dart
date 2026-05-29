// compass_service_mobile.dart
// 모바일(Android/iOS 네이티브) 나침반 — flutter_compass (플랫폼 회전벡터 센서 래핑).
import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';

import 'heading_sample.dart';

class CompassService {
  final _controller = StreamController<HeadingSample>.broadcast();
  Stream<HeadingSample> get stream => _controller.stream;

  StreamSubscription<CompassEvent>? _sub;

  // 웹 구현과 동일한 원형 EMA 스무딩.
  double? _smoothed;
  static const double _alpha = 0.2;

  /// 구독 시작. 반환 false → 나침반 센서 없음(emulator 등) → mock 사용.
  Future<bool> start() async {
    final events = FlutterCompass.events;
    if (events == null) return false;
    _sub = events.listen((CompassEvent e) {
      final h = e.heading; // 0~360, 진북 기준 (nullable)
      if (h == null || h.isNaN) return;
      _controller.add(HeadingSample(_smooth(_wrap360(h)), 'flutter_compass'));
    });
    return true;
  }

  /// 센서 없을 때 mock — heading 슬라이더 값 주입.
  void emitMock(double heading) {
    _controller.add(HeadingSample(_wrap360(heading), 'mock'));
  }

  double _wrap360(double h) => (h % 360 + 360) % 360;

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
    _sub?.cancel();
    _controller.close();
  }
}
