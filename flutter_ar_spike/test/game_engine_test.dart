// test/game_engine_test.dart — GameEngine 상태머신 회귀 (plan_playspot_flutter.md Phase 12).
// Swift GameEngine 의 엣지케이스(완료 게이트 / 지뢰 손실 / Defense 흡수 / Dark zone / Run 타임아웃)를
// 결정론적으로 고정한다. 타이머/네트워크 비의존 — FakeDataSource + 메모리 PlayStateStore.
import 'package:flutter_ar_spike/game/game_engine.dart';
import 'package:flutter_ar_spike/game/play_state_store.dart';
import 'package:flutter_ar_spike/models/game_state.dart';
import 'package:flutter_ar_spike/models/item_quiz.dart';
import 'package:flutter_ar_spike/models/mission.dart';
import 'package:flutter_ar_spike/models/mission_item.dart';
import 'package:flutter_ar_spike/models/item_type.dart';
import 'package:flutter_ar_spike/network/mission_data_source.dart';
import 'package:flutter_ar_spike/services/haptic_service.dart';
import 'package:flutter_ar_spike/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _mid = 'M1';

MissionItem _item(
  int id,
  ItemType type, {
  bool mandatory = false,
  double lat = 37.5,
  double lon = 127.0,
  int range = 30,
  int relation = 0,
  int effectiveTime = 0,
}) =>
    MissionItem(
      missionID: _mid,
      itemID: id,
      mandatory: mandatory ? MandatoryFlag.mandatory : MandatoryFlag.optional,
      itemType: type,
      latitude: lat,
      longitude: lon,
      rangeAR: range,
      relationItemID: relation,
      effectiveTime: effectiveTime,
    );

/// fetchMissionDetail 만 구현하고 나머지는 미사용(테스트 비대상). record* 는 no-op.
class _FakeDataSource implements MissionDataSource {
  final List<MissionItem> items;
  _FakeDataSource(this.items);

  @override
  Future<MissionDetail> fetchMissionDetail(String missionID) async =>
      (Mission(id: missionID, limitTime: 0), items, <ItemQuiz>[]);

  @override
  Future<bool> recordPlayStart(
          {required String missionID, required String playerID, required DateTime startTime, required bool isVirtual}) async =>
      true;
  @override
  Future<bool> recordPlayFinish(
          {required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual}) async =>
      true;
  @override
  Future<bool> recordPlayFail(
          {required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual}) async =>
      true;

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName} 미사용');
}

Future<GameEngine> _engine(List<MissionItem> items) async {
  final e = GameEngine(
    dataSource: _FakeDataSource(items),
    playState: PlayStateStore(),
    soundService: SoundService(),
    hapticService: HapticService(),
    playerID: 'tester',
  );
  await e.setup(missionID: _mid, isNewStart: true, virtualMode: false);
  e.stopTimer(); // 타이머 비의존 — 결정론 유지
  return e;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // HapticFeedback 플랫폼 채널 no-op

  test('완료는 모든 필수 아이템 획득 후에만 성립', () async {
    final start = _item(1, ItemType.start);
    final m1 = _item(2, ItemType.simple, mandatory: true);
    final end = _item(3, ItemType.end);
    final e = await _engine([start, m1, end]);

    e.acquireItem(start);
    expect(e.missionStarted, isTrue);

    e.acquireItem(end); // 필수 m1 미획득 → 완료 안 됨
    expect(e.missionCompleted, isFalse);

    e.acquireItem(m1);
    e.acquireItem(end);
    expect(e.missionCompleted, isTrue);
    expect(e.isMissionEnd, isTrue);
    e.dispose();
  });

  test('End 핀은 필수가 2개 이상 남으면 지도에서 숨김', () async {
    final start = _item(1, ItemType.start);
    final m1 = _item(2, ItemType.simple, mandatory: true);
    final m2 = _item(3, ItemType.simple, mandatory: true);
    final end = _item(4, ItemType.end);
    final e = await _engine([start, m1, m2, end]);

    e.acquireItem(start);
    expect(e.mandatoryRemaining, 2);
    expect(e.shouldShowOnMap(end), isFalse);

    e.acquireItem(m1);
    expect(e.mandatoryRemaining, 1);
    expect(e.shouldShowOnMap(end), isTrue);
    e.dispose();
  });

  test('지뢰 폭발은 최근 획득 아이템을 잃게 함', () async {
    final start = _item(1, ItemType.start);
    final simple = _item(2, ItemType.simple);
    final mine = _item(3, ItemType.mine);
    final e = await _engine([start, simple, mine]);

    e.acquireItem(start);
    e.acquireItem(simple);
    expect(e.dicItemEnd[simple.itemID], 'Y');

    e.handleMineBlast(mine);
    expect(e.dicItemEnd[mine.itemID], 'Y'); // 지뢰는 소모됨
    expect(e.dicItemEnd[simple.itemID], 'N'); // 최근 획득 되돌림
    e.dispose();
  });

  test('Defense(mineNoBomb) 는 지뢰 피해를 1회 흡수', () async {
    final start = _item(1, ItemType.start);
    final defense = _item(2, ItemType.mineNoBomb);
    final simple = _item(3, ItemType.simple);
    final mine = _item(4, ItemType.mine);
    final e = await _engine([start, defense, simple, mine]);

    e.acquireItem(start);
    e.acquireItem(defense);
    e.acquireItem(simple);

    e.handleMineBlast(mine);
    expect(e.dicItemEnd[simple.itemID], 'Y'); // Defense 가 막아 손실 없음
    expect(e.dicRnPTaken[ItemType.mineNoBomb.code], 0); // Defense 1 소모
    e.dispose();
  });

  test('Dark zone 내부 미획득 아이템은 지도에서 숨김', () async {
    final start = _item(1, ItemType.start);
    final dark = _item(2, ItemType.black, lat: 37.5, lon: 127.0, range: 50);
    final inside = _item(3, ItemType.simple, lat: 37.5, lon: 127.0); // 동일 좌표 = 반경 내
    final e = await _engine([start, dark, inside]);

    e.acquireItem(start);
    expect(e.shouldShowOnMap(inside), isFalse); // dark 미획득 → 가림
    e.dispose();
  });

  test('Run End 비활성에서 acquire — SwiftUI 동등 (거부 없이 Y 처리)', () async {
    // SwiftUI GameEngine.swift acquireItem 은 timeoutEnd pre-check 없음.
    // dicItemEnd[id]='Y' 만 setting 되고 isTimeOutActive 는 false(이미 false) 유지.
    final start = _item(1, ItemType.start);
    final runEnd = _item(2, ItemType.timeoutEnd, relation: 99, effectiveTime: 20);
    final e = await _engine([start, runEnd]);

    e.acquireItem(runEnd);
    expect(e.dicItemEnd[runEnd.itemID], 'Y');
    expect(e.isTimeOutActive, isFalse);
    e.dispose();
  });

  test('Run Start 획득 시 타임아웃이 활성화되고 짝 Run End 로 종료', () async {
    final start = _item(1, ItemType.start);
    final runStart = _item(2, ItemType.timeoutStart);
    final runEnd = _item(3, ItemType.timeoutEnd, relation: 2, effectiveTime: 20);
    final e = await _engine([start, runStart, runEnd]);

    e.acquireItem(start);
    e.acquireItem(runStart);
    expect(e.isTimeOutActive, isTrue);
    expect(e.activeTimeoutStartID, runStart.itemID);
    expect(e.timeOutLimitTime, 20);

    e.acquireItem(runEnd);
    expect(e.isTimeOutActive, isFalse);
    expect(e.dicItemEnd[runEnd.itemID], 'Y');
    e.dispose();
  });
}
