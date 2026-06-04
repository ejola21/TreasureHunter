// network/mission_data_source.dart — MissionDataSource.swift 이식 (추상 인터페이스).
// 이번 범위(미션·디자인): read 9 + submitReview + auth 2 + create/update/delete 3.
import '../models/mission.dart';
import '../models/mission_item.dart';
import '../models/item_quiz.dart';
import '../models/mission_reply.dart';
import '../models/ranking_entry.dart';
import 'builder_mission_req.dart';

typedef MissionDetail = (Mission mission, List<MissionItem> items, List<ItemQuiz> quizzes);

abstract interface class MissionDataSource {
  // 읽기
  Future<List<Mission>> fetchMissionList({int cursor = 0, String lang = ''});
  Future<List<Mission>> fetchPublishedMissions(
      {int cursor = 0, String lang = '', required double latitude, required double longitude});
  Future<List<Mission>> fetchTutorialMissions(String region);
  Future<List<Mission>> fetchMyDesigned(String userID);
  Future<List<Mission>> fetchMyPlayed(String userID);
  Future<List<Mission>> fetchCurrentGames(String userID);
  Future<MissionDetail> fetchMissionDetail(String missionID);
  Future<List<MissionReply>> fetchReplies(String missionID);
  Future<List<RankingEntry>> fetchRanking(String missionID);

  // 쓰기 (리뷰)
  Future<bool> submitReview(
      {required String missionID, required String userID, required double score, required String reply});

  // 인증
  Future<bool> login(String email, String password);
  Future<bool> register(String email, String password);

  // 빌더 CUD
  Future<String> createMission(BuilderMissionReq req); // 반환: missionID
  Future<bool> updateMission(String missionID, BuilderMissionReq req);
  Future<bool> deleteMission(String missionID);

  /// `PATCH /api/v1/missions/{id}/status` — 단일 status 전환 (R3.1).
  /// 서버 전이 룰: 0→1→2 단방향만 허용. n→n / 역방향 거부 → 400 INVALID_STATE_TRANSITION.
  Future<bool> updateMissionStatus(String missionID, int status);

  /// `POST /api/v1/badges` — 레거시 뱃지 endpoint. (현재는 uploadFile 권장)
  /// 응답 fileName 을 mission.badgeImageName 에 저장.
  Future<String?> uploadBadgeImage(List<int> bytes, String fileName);

  /// `POST /api/v1/files/upload` — 범용 파일 업로드. SwiftUI MissionBuilderViewModel.save() 가 사용.
  /// 응답 `fileUrl` (S3 전체 URL) 을 그대로 mission.badgeImageName 에 저장하면 됨.
  /// 실패 시 throw.
  Future<String?> uploadFile(List<int> bytes, String fileName);

  // 플레이 기록 (best-effort)
  Future<bool> recordPlayStart(
      {required String missionID, required String playerID, required DateTime startTime, required bool isVirtual});
  Future<bool> recordPlayFinish(
      {required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual});
  Future<bool> recordPlayFail(
      {required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual});
}
