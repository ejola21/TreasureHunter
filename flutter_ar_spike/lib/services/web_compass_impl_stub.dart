// services/web_compass_impl_stub.dart — 비-웹 플랫폼용 stub.
// Android/iOS 네이티브는 sensors_plus/flutter_compass 를 사용하므로 이 stub 은
// 호출되지 않지만, 컴파일 가능해야 하므로 동일 API 를 no-op 으로 제공.
import 'dart:async';

class WebCompass {
  Stream<double> get headingStream => const Stream<double>.empty();
  void start() {}
  Future<void> stop() async {}
  static Future<bool> requestPermission() async => false;
}
