// network/rest_remote_data_source.dart — RestRemoteDataSource.swift 이식 (/api/v1/**).
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kDebugMode;
import '../models/mission.dart';
import '../models/mission_item.dart';
import '../models/item_quiz.dart';
import '../models/mission_reply.dart';
import '../models/ranking_entry.dart';
import 'auth_session.dart';
import 'builder_mission_req.dart';
import 'mission_data_source.dart';
import 'rest_api_client.dart';

class RestRemoteDataSource implements MissionDataSource {
  final RestApiClient _client;
  final AuthSession _auth;
  RestRemoteDataSource(this._client, this._auth);

  List<Mission> _missions(dynamic data) =>
      (data as List<dynamic>? ?? [])
          .map((e) => Mission.fromJson(e as Map<String, dynamic>))
          .toList();

  void _log(String m) => dev.log(m, name: 'RestDS');

  // 읽기 — 실패 시 [] (Swift 동일, 게임 흐름 차단 방지).
  @override
  Future<List<Mission>> fetchMissionList({int cursor = 0, String lang = ''}) async {
    try {
      return _missions(await _client.get('/api/v1/missions', query: {'page': '$cursor'}));
    } catch (e) {
      _log('fetchMissionList: $e');
      return [];
    }
  }

  @override
  Future<List<Mission>> fetchPublishedMissions(
      {int cursor = 0, String lang = '', required double latitude, required double longitude}) async {
    try {
      return _missions(await _client.get('/api/v1/missions/nearby',
          query: {'page': '$cursor', 'latitude': '$latitude', 'longitude': '$longitude'}));
    } catch (e) {
      _log('fetchPublishedMissions: $e');
      return [];
    }
  }

  @override
  Future<List<Mission>> fetchTutorialMissions(String region) async {
    try {
      return _missions(await _client.get('/api/v1/missions/tutorial', query: {'lang': region}));
    } catch (e) {
      _log('fetchTutorialMissions: $e');
      return [];
    }
  }

  @override
  Future<List<Mission>> fetchMyDesigned(String userID) async {
    try {
      return _missions(await _client.get('/api/v1/users/${Uri.encodeComponent(userID)}/missions/designed'));
    } catch (e) {
      _log('fetchMyDesigned: $e');
      return [];
    }
  }

  @override
  Future<List<Mission>> fetchMyPlayed(String userID) async {
    try {
      return _missions(await _client.get('/api/v1/users/${Uri.encodeComponent(userID)}/missions/played'));
    } catch (e) {
      _log('fetchMyPlayed: $e');
      return [];
    }
  }

  @override
  Future<List<Mission>> fetchCurrentGames(String userID) async {
    try {
      return _missions(await _client.get('/api/v1/users/${Uri.encodeComponent(userID)}/missions/playing'));
    } catch (e) {
      _log('fetchCurrentGames: $e');
      return [];
    }
  }

  @override
  Future<MissionDetail> fetchMissionDetail(String missionID) async {
    final data = await _client.get('/api/v1/missions/${Uri.encodeComponent(missionID)}') as Map<String, dynamic>;
    final mission = Mission.fromJson(data['mission'] as Map<String, dynamic>);
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => MissionItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final quizzes = (data['quizzes'] as List<dynamic>? ?? []).map((e) {
      final q = e as Map<String, dynamic>;
      return ItemQuiz(
        missionID: missionID,
        itemID: (q['ItemID'] as num).toInt(),
        seq: (q['Seq'] as num).toInt(),
        quiz: q['Quiz'] as String? ?? '',
        answer: q['Answer'] as String? ?? '',
        probability: (q['Probability'] as num?)?.toInt() ?? 100,
      );
    }).toList();
    return (mission, items, quizzes);
  }

  @override
  Future<List<MissionReply>> fetchReplies(String missionID) async {
    try {
      final rows = await _client.get('/api/v1/missions/${Uri.encodeComponent(missionID)}/replies') as List<dynamic>? ?? [];
      return rows
          .map((e) => MissionReply.fromJson(e as Map<String, dynamic>))
          .whereType<MissionReply>()
          .toList();
    } catch (e) {
      _log('fetchReplies: $e');
      return [];
    }
  }

  @override
  Future<List<RankingEntry>> fetchRanking(String missionID) async {
    try {
      final r = await _client.get('/api/v1/missions/${Uri.encodeComponent(missionID)}/ranking') as Map<String, dynamic>;
      final entries = <RankingEntry>[];
      final pairs = [
        (1, r['ShortUser1'] as String?, r['ShortRecord1'] as String?),
        (2, r['ShortUser2'] as String?, r['ShortRecord2'] as String?),
        (3, r['ShortUser3'] as String?, r['ShortRecord3'] as String?),
      ];
      for (final (idx, user, record) in pairs) {
        if (user == null || user.isEmpty) continue;
        entries.add(RankingEntry(id: idx, userName: user, record: record ?? ''));
      }
      return entries;
    } catch (e) {
      _log('fetchRanking: $e');
      return [];
    }
  }

  @override
  Future<bool> submitReview(
      {required String missionID, required String userID, required double score, required String reply}) async {
    try {
      await _client.send('POST', '/api/v1/missions/${Uri.encodeComponent(missionID)}/replies',
          body: {'userId': userID, 'score': score, 'reply': reply});
      return true;
    } catch (e) {
      _log('submitReview: $e');
      return false;
    }
  }

  // 인증
  /// 디버그 빌드 한정 테스트 계정 (서버 우회).
  static const _devEmail = 'test@gmail.com';
  static const _devPassword = '1234';
  bool _isDevAccount(String e, String p) =>
      kDebugMode && e == _devEmail && p == _devPassword;

  @override
  Future<bool> login(String email, String password) async {
    // 디버그 테스트 계정 — 서버 호출 없이 즉시 성공.
    if (_isDevAccount(email, password)) {
      await _auth.setToken('dev_test_token');
      await _auth.saveCredentials(email, password);
      _auth.userId = email;
      _log('login: dev bypass for $email');
      return true;
    }
    try {
      final res = await _client.send('POST', '/api/v1/auth/login',
          body: {'userId': email, 'password': password}) as Map<String, dynamic>;
      final token = res['token'] as String?;
      if (token == null) return false;
      await _auth.setToken(token);
      await _auth.saveCredentials(email, password);
      _auth.userId = email; // setter 가 notifyListeners → Settings 등 자동 갱신
      return true;
    } catch (e) {
      _log('login: $e');
      return false;
    }
  }

  @override
  Future<bool> register(String email, String password) async {
    // 디버그 테스트 계정 — 서버 호출 없이 즉시 가입 성공 (이후 login 호출도 통과).
    if (_isDevAccount(email, password)) {
      _log('register: dev bypass for $email');
      return true;
    }
    try {
      await _client.send('POST', '/api/v1/auth/register',
          body: {'userId': email, 'password': password});
      return true;
    } catch (e) {
      // DUPLICATE_DATA(이미 가입) 는 login 진행 가능 → true 로 흡수.
      if (e.toString().contains('DUPLICATE_DATA')) return true;
      _log('register: $e');
      return false;
    }
  }

  // 빌더 CUD — 실패 시 rethrow (호출부에서 분기).
  @override
  Future<String> createMission(BuilderMissionReq req) async {
    final res = await _client.send('POST', '/api/v1/missions', body: req.toJson()) as Map<String, dynamic>;
    return res['missionId'] as String;
  }

  @override
  Future<bool> updateMission(String missionID, BuilderMissionReq req) async {
    await _client.send('PATCH', '/api/v1/missions/${Uri.encodeComponent(missionID)}', body: req.toJson());
    return true;
  }

  @override
  Future<bool> deleteMission(String missionID) async {
    await _client.send('DELETE', '/api/v1/missions/${Uri.encodeComponent(missionID)}');
    return true;
  }

  /// SwiftUI RestRemoteDataSource.uploadFile 1:1 — POST /api/v1/files/upload (multipart `file`).
  /// 응답 `fileUrl` (S3 전체 https URL) 을 그대로 반환. mission.badgeImageName 에 저장하면 됨.
  /// `BadgeImageName: "https://playspot-badge-dev.s3.amazonaws.com/file/..."`
  @override
  Future<String?> uploadFile(List<int> bytes, String fileName) async {
    final lower = fileName.toLowerCase();
    final mime = lower.endsWith('.jpg') || lower.endsWith('.jpeg')
        ? 'image/jpeg'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/png';
    final res = await _client.uploadFile('/api/v1/files/upload',
        fieldName: 'file', fileName: fileName, mimeType: mime, bytes: bytes);
    if (res is Map) {
      final url = (res['fileUrl'] as String?) ?? (res['fileName'] as String?);
      if (url != null && url.isNotEmpty) return url;
    }
    _log('uploadFile: unexpected response: $res');
    return null;
  }

  /// 레거시 `POST /api/v1/badges` — 호환용. 신규 흐름은 uploadFile 사용.
  @override
  Future<String?> uploadBadgeImage(List<int> bytes, String fileName) async {
    final lower = fileName.toLowerCase();
    final mime = lower.endsWith('.jpg') || lower.endsWith('.jpeg')
        ? 'image/jpeg'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/png';
    try {
      final res = await _client.uploadFile('/api/v1/badges',
          fieldName: 'file', fileName: fileName, mimeType: mime, bytes: bytes);
      if (res is Map) {
        final n = (res['fileName'] as String?) ??
            (res['fileUrl'] as String?) ??
            (res['url'] as String?);
        if (n != null && n.isNotEmpty) return n;
      }
      _log('uploadBadgeImage: unexpected response shape: $res');
      return null;
    } catch (e) {
      _log('uploadBadgeImage: $e');
      rethrow; // 호출자가 사용자에게 정확한 에러 메시지 전달.
    }
  }

  // 플레이 기록 — KST "yyyy-MM-dd HH:mm:ss", best-effort.
  static String _kst(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  Future<bool> _recordPlay(String missionID, String path, Map<String, dynamic> body) async {
    try {
      await _client.send('POST', '/api/v1/missions/${Uri.encodeComponent(missionID)}/plays/$path', body: body);
      return true;
    } catch (e) {
      _log('recordPlay/$path: $e');
      return false;
    }
  }

  @override
  Future<bool> recordPlayStart(
      {required String missionID, required String playerID, required DateTime startTime, required bool isVirtual}) {
    return _recordPlay(missionID, 'start',
        {'playerId': playerID, 'startTime': _kst(startTime), 'isVirtual': isVirtual ? 1 : 0});
  }

  @override
  Future<bool> recordPlayFinish(
      {required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual}) {
    return _recordPlay(missionID, 'finish',
        {'playerId': playerID, 'startTime': _kst(startTime), 'endTime': _kst(endTime), 'isVirtual': isVirtual ? 1 : 0});
  }

  @override
  Future<bool> recordPlayFail(
      {required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual}) {
    return _recordPlay(missionID, 'fail',
        {'playerId': playerID, 'startTime': _kst(startTime), 'endTime': _kst(endTime), 'isVirtual': isVirtual ? 1 : 0});
  }
}
