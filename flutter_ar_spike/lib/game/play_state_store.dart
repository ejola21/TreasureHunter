// game/play_state_store.dart — 플레이 상태 저장소 (PlayStateRepository + PowerUpRepository 대응).
// 현재 in-memory 구현 (세션 동안 유지). 인터페이스는 drift 영속화로 교체 가능하게 설계.
import 'play_models.dart';

class PlayStateStore {
  // key = "missionID|playerID"
  final Map<String, MissionInPlay> _missions = {};
  final Map<String, Map<int, MissionItemInPlay>> _items = {};
  final Map<String, Map<String, ItemRnPInPlay>> _powerUps = {};

  String _key(String m, String p) => '$m|$p';

  // MissionInPlay
  MissionInPlay? fetchMissionInPlay(String missionID, String playerID) =>
      _missions[_key(missionID, playerID)];

  void upsertMissionInPlay(MissionInPlay v) =>
      _missions[_key(v.missionID, v.playerID)] = v;

  // MissionItemInPlay
  Map<int, String> fetchItemStatuses(String missionID, String playerID) {
    final m = _items[_key(missionID, playerID)] ?? {};
    return {for (final e in m.entries) e.key: e.value.endYN};
  }

  MissionItemInPlay? fetchItemInPlay(String missionID, String playerID, int itemID) =>
      _items[_key(missionID, playerID)]?[itemID];

  void upsertItemInPlay(MissionItemInPlay v) {
    final map = _items.putIfAbsent(_key(v.missionID, v.playerID), () => {});
    map[v.itemID] = v;
  }

  // ItemRnPInPlay (파워업)
  List<ItemRnPInPlay> fetchPowerUps(String missionID, String playerID) =>
      (_powerUps[_key(missionID, playerID)] ?? {}).values.toList();

  void upsertPowerUp(ItemRnPInPlay v) {
    final map = _powerUps.putIfAbsent(_key(v.missionID, v.playerID), () => {});
    map[v.itemType] = v;
  }

  // 신규 시작 시 초기화
  void deleteAll(String missionID, String playerID) {
    final k = _key(missionID, playerID);
    _missions.remove(k);
    _items.remove(k);
    _powerUps.remove(k);
  }
}
