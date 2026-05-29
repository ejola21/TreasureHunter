// network/rest_remote_data_source.dart — RestRemoteDataSource.swift 이식 (/api/v1/**).
import 'dart:developer' as dev;
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
  @override
  Future<bool> login(String email, String password) async {
    try {
      final res = await _client.send('POST', '/api/v1/auth/login',
          body: {'userId': email, 'password': password}) as Map<String, dynamic>;
      final token = res['token'] as String?;
      if (token == null) return false;
      await _auth.setToken(token);
      await _auth.saveCredentials(email, password);
      return true;
    } catch (e) {
      _log('login: $e');
      return false;
    }
  }

  @override
  Future<bool> register(String email, String password) async {
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
}
