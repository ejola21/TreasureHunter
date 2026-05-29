// models/parse_utils.dart — Swift 커스텀 디코딩 로직 이식 (LimitTime/날짜 다중포맷).

/// "HH:MM:SS" → 총 초. 실패/빈 문자열 → 0 (무제한). TimerFormatter.parseHMS 대응.
int parseHms(String? s) {
  if (s == null) return 0;
  final parts = s.split(':');
  if (parts.length != 3) return 0;
  final nums = parts.map((p) => int.tryParse(p) ?? -1).toList();
  if (nums.any((n) => n < 0)) return 0;
  return nums[0] * 3600 + nums[1] * 60 + nums[2];
}

/// 총 초 → "HH:MM:SS". TimerFormatter.hms 대응 (createMission LimitTime 인코딩용).
String hmsString(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
}

/// 서버 날짜 다중 포맷 수용: ISO8601(+frac/tz) / "yyyy-MM-ddTHH:mm:ss" / "yyyy-MM-dd"
/// / "yyyy-MM-dd HH:mm:ss". 실패 시 null. (Mission/MissionReply parseDate 통합)
DateTime? parseFlexibleDate(String? s) {
  if (s == null || s.isEmpty) return null;
  // 1) ISO8601 (DateTime.parse 가 +00:00, .000, T 구분자 모두 처리)
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  // 2) "yyyy-MM-dd HH:mm:ss" → 공백을 T 로 치환 후 재시도
  final t = DateTime.tryParse(s.replaceFirst(' ', 'T'));
  if (t != null) return t;
  return null;
}
