// compass_service.dart — 플랫폼 분기 파사드.
// 웹은 DeviceOrientationEvent(JS interop), 모바일/데스크톱은 flutter_compass 구현을 쓴다.
// 두 구현은 동일한 public API (CompassService: stream / start / emitMock / dispose) 를 노출.
export 'heading_sample.dart';
export 'compass_service_web.dart'
    if (dart.library.io) 'compass_service_mobile.dart';
