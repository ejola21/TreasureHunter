// features/missions/mission_providers.dart — 미션 목록/상세/리뷰/랭킹 provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/mission.dart';
import '../../models/mission_reply.dart';
import '../../models/ranking_entry.dart';
import '../../network/app_config.dart';
import '../../network/mission_data_source.dart';

/// 전체 미션 (page 0). 인기/신규 세그는 이걸 클라이언트 정렬해 파생.
final allMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  await ref.read(authBootstrapProvider).ensureAuthenticated();
  return ref.read(dataSourceProvider).fetchMissionList();
});

/// 내 주변 — geolocator 위치로 nearby. 위치 실패 시 서울 기본좌표 폴백.
final nearbyMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  await ref.read(authBootstrapProvider).ensureAuthenticated();
  var lat = 37.5665, lon = 126.9780; // 서울 폴백
  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
      final p = await Geolocator.getCurrentPosition();
      lat = p.latitude;
      lon = p.longitude;
    }
  } catch (_) {/* 폴백 좌표 사용 */}
  return ref.read(dataSourceProvider).fetchPublishedMissions(latitude: lat, longitude: lon);
});

final missionDetailProvider = FutureProvider.family<MissionDetail, String>((ref, id) async {
  await ref.read(authBootstrapProvider).ensureAuthenticated();
  return ref.read(dataSourceProvider).fetchMissionDetail(id);
});

final repliesProvider = FutureProvider.family<List<MissionReply>, String>(
    (ref, id) async => ref.read(dataSourceProvider).fetchReplies(id));

final rankingProvider = FutureProvider.family<List<RankingEntry>, String>(
    (ref, id) async => ref.read(dataSourceProvider).fetchRanking(id));
