// services/web_shake_impl_stub.dart — 비-웹 플랫폼용 stub.
// Android/iOS 네이티브는 sensors_plus 사용하므로 호출되지 않지만 컴파일을 위해 필요.
import 'dart:async';

class WebShake {
  Stream<double> get magnitudeStream => const Stream<double>.empty();
  void start() {}
  Future<void> stop() async {}
  static Future<bool> requestPermission() async => false;
}
