// test/unit/items/_helpers.dart — 아이템별 단위 테스트 공용 헬퍼.
// SwiftUI GameEngine.swift 의 acquireItem / _setAcquiredAlert 분기를 1:1 검증한다.
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

const mid = 'M1';

MissionItem item({
  required int id,
  required ItemType type,
  bool mandatory = false,
  double lat = 37.5,
  double lon = 127.0,
  int range = 30,
  int relation = 0,
  int effectiveTime = 0,
  int itemGame = 0,
  String info = '',
}) =>
    MissionItem(
      missionID: mid,
      itemID: id,
      mandatory: mandatory ? MandatoryFlag.mandatory : MandatoryFlag.optional,
      itemType: type,
      latitude: lat,
      longitude: lon,
      rangeAR: range,
      relationItemID: relation,
      effectiveTime: effectiveTime,
      itemGame: itemGame,
      info: info,
    );

/// fetchMissionDetail 만 구현. 나머지는 noSuchMethod → UnimplementedError.
class FakeDataSource implements MissionDataSource {
  final List<MissionItem> items;
  final List<ItemQuiz> quizzes;
  FakeDataSource(this.items, {this.quizzes = const []});

  @override
  Future<MissionDetail> fetchMissionDetail(String missionID) async =>
      (Mission(id: missionID, limitTime: 0), items, quizzes);

  @override
  Future<bool> recordPlayStart({required String missionID, required String playerID, required DateTime startTime, required bool isVirtual}) async => true;
  @override
  Future<bool> recordPlayFinish({required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual}) async => true;
  @override
  Future<bool> recordPlayFail({required String missionID, required String playerID, required DateTime startTime, required DateTime endTime, required bool isVirtual}) async => true;

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName} 미사용');
}

class TestEngine {
  final GameEngine engine;
  final FakeSoundService sound;
  final FakeHapticService haptic;
  TestEngine(this.engine, this.sound, this.haptic);

  void dispose() {
    engine.stopTimer();
    engine.dispose();
  }
}

Future<TestEngine> buildEngine(
  List<MissionItem> items, {
  List<ItemQuiz> quizzes = const [],
  int limitTime = 0,
}) async {
  final sound = FakeSoundService();
  final haptic = FakeHapticService();
  final ds = FakeDataSource(items, quizzes: quizzes);
  final e = GameEngine(
    dataSource: ds,
    playState: PlayStateStore(),
    soundService: sound,
    hapticService: haptic,
    playerID: 'tester',
  );
  await e.setup(missionID: mid, isNewStart: true, virtualMode: false);
  e.stopTimer(); // 결정론 — 타이머 비의존
  return TestEngine(e, sound, haptic);
}
