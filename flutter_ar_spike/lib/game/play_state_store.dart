// game/play_state_store.dart — 플레이 상태 저장소 (PlayStateRepository + PowerUpRepository 대응).
//
// drift 영속화 (SQLite) + in-memory 캐시 하이브리드.
// - 읽기는 sync — 메모리 캐시에서 즉시 반환 (게임루프 블로킹 X)
// - 쓰기는 메모리 + drift fire-and-forget — cold restart 안전
// - `hydrate()` 로 미션 시작 시 디스크 → 메모리 1회 로드
// - `deleteAll()` 은 async — 새 미션 시작 시 전 row 삭제 (트랜잭션)
//
// 레가시: Classes/Dao/ItemRnPInPlayDao.m, Classes/Dao/MissionInPlayDao 대응.
// 스위프트: PlaySpot/Database/PowerUpRepository.swift 대응.
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import 'play_models.dart';

class PlayStateStore {
  final AppDatabase _db;

  // key = "missionID|playerID"
  final Map<String, MissionInPlay> _missions = {};
  final Map<String, Map<int, MissionItemInPlay>> _items = {};
  final Map<String, Map<String, ItemRnPInPlay>> _powerUps = {};

  PlayStateStore(this._db);

  String _key(String m, String p) => '$m|$p';

  /// 미션 진입 시 1회 호출 — 디스크 → 메모리 캐시 채움.
  /// 이후 모든 sync read 는 캐시 hit.
  Future<void> hydrate(String missionID, String playerID) async {
    final k = _key(missionID, playerID);

    final missionRow = await _db.fetchMissionInPlay(missionID, playerID);
    if (missionRow != null) {
      _missions[k] = MissionInPlay(
        missionID: missionRow.missionID,
        playerID: missionRow.playerID,
        startYN: missionRow.startYN,
        endYN: missionRow.endYN,
        startTime: missionRow.startTime,
        endTime: missionRow.endTime,
      );
    } else {
      _missions.remove(k);
    }

    final itemRows = await _db.fetchAllItemInPlay(missionID, playerID);
    _items[k] = {
      for (final r in itemRows)
        r.itemID: MissionItemInPlay(
          missionID: r.missionID,
          playerID: r.playerID,
          itemID: r.itemID,
          endYN: r.endYN,
          failCnt: r.failCnt,
          startTime: r.startTime,
          endTime: r.endTime,
          quizSeq: r.quizSeq,
        ),
    };

    final puRows = await _db.fetchAllPowerUps(missionID, playerID);
    _powerUps[k] = {
      for (final r in puRows)
        r.itemType: ItemRnPInPlay(
          missionID: r.missionID,
          playerID: r.playerID,
          itemType: r.itemType,
          ableCnt: r.ableCnt,
          ableTime: r.ableTime,
          acquiredTime: r.acquiredTime,
        ),
    };
  }

  // ─── MissionInPlay ─────────────────────────────────────────────────

  MissionInPlay? fetchMissionInPlay(String missionID, String playerID) =>
      _missions[_key(missionID, playerID)];

  void upsertMissionInPlay(MissionInPlay v) {
    _missions[_key(v.missionID, v.playerID)] = v;
    // fire-and-forget: 게임루프 블로킹 X. 실패는 다음 hydrate 에 의해 복구.
    _db.upsertMissionInPlay(MissionInPlayTableCompanion(
      missionID: Value(v.missionID),
      playerID: Value(v.playerID),
      startYN: Value(v.startYN),
      endYN: Value(v.endYN),
      startTime: Value(v.startTime),
      endTime: Value(v.endTime),
    ));
  }

  // ─── MissionItemInPlay ────────────────────────────────────────────

  Map<int, String> fetchItemStatuses(String missionID, String playerID) {
    final m = _items[_key(missionID, playerID)] ?? {};
    return {for (final e in m.entries) e.key: e.value.endYN};
  }

  MissionItemInPlay? fetchItemInPlay(String missionID, String playerID, int itemID) =>
      _items[_key(missionID, playerID)]?[itemID];

  void upsertItemInPlay(MissionItemInPlay v) {
    final map = _items.putIfAbsent(_key(v.missionID, v.playerID), () => {});
    map[v.itemID] = v;
    _db.upsertItemInPlay(MissionItemInPlayTableCompanion(
      missionID: Value(v.missionID),
      playerID: Value(v.playerID),
      itemID: Value(v.itemID),
      endYN: Value(v.endYN),
      failCnt: Value(v.failCnt),
      startTime: Value(v.startTime),
      endTime: Value(v.endTime),
      quizSeq: Value(v.quizSeq),
    ));
  }

  // ─── ItemRnPInPlay (파워업) ───────────────────────────────────────

  List<ItemRnPInPlay> fetchPowerUps(String missionID, String playerID) =>
      (_powerUps[_key(missionID, playerID)] ?? {}).values.toList();

  void upsertPowerUp(ItemRnPInPlay v) {
    final map = _powerUps.putIfAbsent(_key(v.missionID, v.playerID), () => {});
    map[v.itemType] = v;
    _db.upsertPowerUp(ItemRnPInPlayTableCompanion(
      missionID: Value(v.missionID),
      playerID: Value(v.playerID),
      itemType: Value(v.itemType),
      ableCnt: Value(v.ableCnt),
      ableTime: Value(v.ableTime),
      acquiredTime: Value(v.acquiredTime),
    ));
  }

  // ─── 청소 ──────────────────────────────────────────────────────────

  /// 새 미션 시작 시 (isNewStart=true) 호출. 트랜잭션으로 3 테이블 전체 row 삭제.
  Future<void> deleteAll(String missionID, String playerID) async {
    final k = _key(missionID, playerID);
    _missions.remove(k);
    _items.remove(k);
    _powerUps.remove(k);
    await _db.deleteAllForMission(missionID, playerID);
  }
}
