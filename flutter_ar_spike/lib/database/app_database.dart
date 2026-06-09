/// 플레이 상태 영속화 SQLite DB.
///
/// 레가시 `Resources/treasure.sqlite` 의 3 테이블 (`MissionInPlay`,
/// `MissionItemInPlay`, `ItemRnPInPlay`) 을 drift 로 이식.
/// - 레거시 Obj-C: FMDB raw SQL
/// - mvp 스위프트: GRDB
/// - mvp 플러터: drift (Dart 코드젠 타입세이프 래퍼) — **본 파일**
///
/// 코드젠 후 `app_database.g.dart` 생성됨 — `dart run build_runner build`.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── 테이블 정의 ──────────────────────────────────────────────────────

/// 미션 진행 상태 — 시작/종료 시각·플래그.
/// PK: (missionID, playerID)
class MissionInPlayTable extends Table {
  TextColumn get missionID => text()();
  TextColumn get playerID => text()();
  TextColumn get startYN => text().withDefault(const Constant('N'))();
  TextColumn get endYN => text().withDefault(const Constant('N'))();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {missionID, playerID};

  @override
  String get tableName => 'mission_in_play';
}

/// 아이템별 진행 상태 — 완료 여부·실패 카운트·퀴즈 시퀀스.
/// PK: (missionID, playerID, itemID)
class MissionItemInPlayTable extends Table {
  TextColumn get missionID => text()();
  TextColumn get playerID => text()();
  IntColumn get itemID => integer()();
  TextColumn get endYN => text().withDefault(const Constant('N'))();
  IntColumn get failCnt => integer().withDefault(const Constant(0))();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get quizSeq => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {missionID, playerID, itemID};

  @override
  String get tableName => 'mission_item_in_play';
}

/// 파워업/방해물 런타임 상태 — 노밤(`mineNoBomb`) 잔여 차감 카운트 등.
/// PK: (missionID, playerID, itemType)
class ItemRnPInPlayTable extends Table {
  TextColumn get missionID => text()();
  TextColumn get playerID => text()();
  TextColumn get itemType => text()();
  IntColumn get ableCnt => integer().withDefault(const Constant(1))();
  DateTimeColumn get ableTime => dateTime().nullable()();
  DateTimeColumn get acquiredTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {missionID, playerID, itemType};

  @override
  String get tableName => 'item_rnp_in_play';
}

// ─── DB 본체 ──────────────────────────────────────────────────────────

@DriftDatabase(tables: [MissionInPlayTable, MissionItemInPlayTable, ItemRnPInPlayTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() =>
      driftDatabase(name: 'play_spot', native: const DriftNativeOptions());

  // ─── MissionInPlay ────────────────────────────────────────────────

  Future<MissionInPlayTableData?> fetchMissionInPlay(String missionID, String playerID) {
    return (select(missionInPlayTable)
          ..where((t) => t.missionID.equals(missionID) & t.playerID.equals(playerID)))
        .getSingleOrNull();
  }

  Future<void> upsertMissionInPlay(MissionInPlayTableCompanion data) {
    return into(missionInPlayTable).insertOnConflictUpdate(data);
  }

  // ─── MissionItemInPlay ────────────────────────────────────────────

  Future<List<MissionItemInPlayTableData>> fetchAllItemInPlay(String missionID, String playerID) {
    return (select(missionItemInPlayTable)
          ..where((t) => t.missionID.equals(missionID) & t.playerID.equals(playerID)))
        .get();
  }

  Future<void> upsertItemInPlay(MissionItemInPlayTableCompanion data) {
    return into(missionItemInPlayTable).insertOnConflictUpdate(data);
  }

  // ─── ItemRnPInPlay ────────────────────────────────────────────────

  Future<List<ItemRnPInPlayTableData>> fetchAllPowerUps(String missionID, String playerID) {
    return (select(itemRnPInPlayTable)
          ..where((t) => t.missionID.equals(missionID) & t.playerID.equals(playerID)))
        .get();
  }

  Future<void> upsertPowerUp(ItemRnPInPlayTableCompanion data) {
    return into(itemRnPInPlayTable).insertOnConflictUpdate(data);
  }

  // ─── 청소 ────────────────────────────────────────────────────────

  /// 미션 시작 시 (isNewStart) 호출 — 동일 (missionID, playerID) 전 row 삭제.
  /// 레가시 MissionPlay.m:822-827, ARViewController 청소 흐름 대응.
  Future<void> deleteAllForMission(String missionID, String playerID) async {
    await transaction(() async {
      await (delete(missionInPlayTable)
            ..where((t) => t.missionID.equals(missionID) & t.playerID.equals(playerID)))
          .go();
      await (delete(missionItemInPlayTable)
            ..where((t) => t.missionID.equals(missionID) & t.playerID.equals(playerID)))
          .go();
      await (delete(itemRnPInPlayTable)
            ..where((t) => t.missionID.equals(missionID) & t.playerID.equals(playerID)))
          .go();
    });
  }
}
