/// 마커 인식 이벤트 로깅 (Day 5 — 인식률 측정용).
/// CSV 라인을 SharedPreferences 에 누적, "Export" 버튼으로 stdout 출력.
library;

import 'package:shared_preferences/shared_preferences.dart';

class DetectionEvent {
  final DateTime timestamp;
  final String markerId;
  final int latencyMs; // ARView 진입 → 인식 까지 (옵션)
  final String device;

  DetectionEvent({
    required this.timestamp,
    required this.markerId,
    required this.latencyMs,
    required this.device,
  });

  String toCsvLine() =>
      '${timestamp.toIso8601String()},$markerId,$latencyMs,$device';
}

class DetectionLogger {
  static const _key = 'detection_log_csv';

  Future<void> log(DetectionEvent e) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key) ?? 'timestamp,marker_id,latency_ms,device\n';
    await prefs.setString(_key, '$existing${e.toCsvLine()}\n');
  }

  Future<String> exportCsv() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ??
        'timestamp,marker_id,latency_ms,device\n(empty)';
  }

  Future<int> countEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString(_key) ?? '';
    return csv.split('\n').where((l) => l.contains(',')).length - 1; // minus header
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
