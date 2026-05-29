// models/mission_reply.dart — MissionReply.swift 이식 (리뷰/평점).
import 'parse_utils.dart';

class MissionReply {
  final String text;
  final double? score; // 1.0 ~ 5.0
  final String? nickname;
  final DateTime? writeDate;

  const MissionReply({required this.text, this.score, this.nickname, this.writeDate});

  /// ReplyRes → MissionReply. text 비면 null 반환(호출부에서 필터).
  static MissionReply? fromJson(Map<String, dynamic> j) {
    final text = j['MReply'] as String?;
    if (text == null || text.isEmpty) return null;
    return MissionReply(
      text: text,
      score: (j['Score'] as num?)?.toDouble(),
      nickname: j['Nickname'] as String?,
      writeDate: parseFlexibleDate(j['WriteDate'] as String?),
    );
  }
}
