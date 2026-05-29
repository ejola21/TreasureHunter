// ar_coordinate.dart
// PlaySpot/AR/ARCoordinate.swift 를 Dart 로 포팅.
// GPS 좌표 두 점으로 진북 기준 방위각(azimuth)과 거리(radialDistance)를 계산.
import 'dart:math';

/// 위경도 좌표.
class LatLng {
  final double lat;
  final double lon;
  const LatLng(this.lat, this.lon);
}

/// 원점(플레이어) 기준의 극좌표 — Swift ARCoordinate 대응.
class ArCoordinate {
  /// 원점으로부터의 거리 (미터).
  final double radialDistance;

  /// 진북 기준 방위각 (라디안).
  final double azimuth;

  const ArCoordinate({required this.radialDistance, required this.azimuth});

  /// Swift `ARCoordinate.from(location:origin:)` 대응.
  static ArCoordinate from({required LatLng item, required LatLng origin}) {
    return ArCoordinate(
      radialDistance: _haversineMeters(origin, item),
      azimuth: bearingRadians(from: origin, to: item),
    );
  }

  /// Swift `ARCoordinate.bearing(from:to:)` 와 동일한 great-circle 방위각.
  static double bearingRadians({required LatLng from, required LatLng to}) {
    final lat1 = _rad(from.lat);
    final lon1 = _rad(from.lon);
    final lat2 = _rad(to.lat);
    final lon2 = _rad(to.lon);
    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    return atan2(y, x);
  }

  /// CLLocation.distance(from:) 근사 — Haversine (짧은 거리에서 충분히 정확).
  static double _haversineMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _rad(b.lat - a.lat);
    final dLon = _rad(b.lon - a.lon);
    final lat1 = _rad(a.lat);
    final lat2 = _rad(b.lat);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _rad(double deg) => deg * pi / 180.0;
}

/// 각도를 -π ~ π 로 정규화 (방위각 wrap-around 보정). ARGameView.swift 의 normalizeAngle.
double normalizeAngle(double angle) {
  var a = angle;
  while (a > pi) {
    a -= 2 * pi;
  }
  while (a < -pi) {
    a += 2 * pi;
  }
  return a;
}
