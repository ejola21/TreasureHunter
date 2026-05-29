// location_service.dart
// geolocator 기반 GPS 권한 + 위치 스트림. Web 은 브라우저 권한 프롬프트 자동.
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 위치 권한 확보. Web 에서는 브라우저 프롬프트가 뜬다.
  Future<bool> ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// 1m 이동마다 갱신되는 위치 스트림 (plan W2: 1Hz 이상 목표).
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    );
  }
}
