// game/game_engine.dart — GameEngine.swift 이식 (게임 상태머신).
// 카탈로그는 dataSource.fetchMissionDetail 로 로드, 플레이 상태는 PlayStateStore(메모리),
// 서버 기록은 recordPlay*. acquire/mine/run start·end/quiz/gambling/dark zone/counters 포팅.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/item_type.dart';
import '../models/mission.dart';
import '../models/mission_item.dart';
import '../network/mission_data_source.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'play_alert.dart';
import 'play_models.dart';
import 'play_state_store.dart';
import 'virtual_mode.dart';

const _distance = Distance();

class GameEngine extends ChangeNotifier {
  final MissionDataSource _ds;
  final PlayStateStore _store;
  final SoundService _sound;
  final HapticService _haptic;
  final String playerID;

  GameEngine({
    required MissionDataSource dataSource,
    required PlayStateStore playState,
    required SoundService soundService,
    required HapticService hapticService,
    required this.playerID,
  })  : _ds = dataSource,
        _store = playState,
        _sound = soundService,
        _haptic = hapticService;

  // 상태
  bool missionStarted = false;
  bool missionCompleted = false;
  bool isMissionEnd = false;
  bool isVirtualMode = false;
  bool virtualOffsetApplied = false;

  final Map<int, String> dicItemEnd = {}; // itemID -> "Y"/"N"
  final Map<String, int> dicRnPTaken = {}; // itemType.code -> ableCnt

  DateTime? missionStartTime;
  DateTime? timeOutStartTime;
  int timeOutLimitTime = 0;
  bool isTimeOutActive = false;
  int? activeTimeoutStartID;

  double elapsedTime = 0;
  double remainingRunTime = 0;
  int missionLimitSeconds = 0;
  double remainingMissionTime = 0;
  bool missionTimedOut = false;

  int mineCount = 0, mandatoryRemaining = 0, hiddenOnMapCount = 0, stealthOnARCount = 0;

  ItemAcquiredAlert? pendingAlert;
  final List<ItemAcquiredAlert> _alertQueue = [];
  final List<int> _acquisitionOrder = [];

  Mission? mission;
  List<MissionItem> items = [];
  Timer? _timer;
  LatLng? playerLocation;

  String get missionID => mission?.id ?? '';

  // MARK: setup
  Future<void> setup({
    required String missionID,
    required bool isNewStart,
    required bool virtualMode,
    LatLng? playerLocation,
  }) async {
    isVirtualMode = virtualMode;
    this.playerLocation = playerLocation;

    final (m, fetchedItems, quizzes) = await _ds.fetchMissionDetail(missionID);
    final byItem = <int, List<dynamic>>{};
    for (final q in quizzes) {
      (byItem[q.itemID] ??= []).add(q);
    }
    for (final it in fetchedItems) {
      if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
        it.quizzes = quizzes.where((q) => q.itemID == it.itemID).toList();
      }
    }
    m.items = fetchedItems;

    if (isNewStart) _store.deleteAll(missionID, playerID);
    _acquisitionOrder.clear();

    var playState = _store.fetchMissionInPlay(missionID, playerID);
    if (playState == null) {
      final hasStart = fetchedItems.any((it) => it.itemType == ItemType.start);
      playState = MissionInPlay(
        missionID: missionID,
        playerID: playerID,
        startYN: hasStart ? 'N' : 'Y',
        startTime: hasStart ? null : DateTime.now(),
      );
      _store.upsertMissionInPlay(playState);
      missionStarted = !hasStart;
      if (!hasStart) {
        _sound.play(SoundEffect.gogogo);
        _recordPlay(_PlayAction.start, playState.startTime ?? DateTime.now());
      }
    } else {
      missionStarted = playState.hasStarted;
    }
    if (missionStarted) missionStartTime = playState.startTime;

    dicItemEnd
      ..clear()
      ..addAll(_store.fetchItemStatuses(missionID, playerID));
    dicRnPTaken.clear();
    for (final pu in _store.fetchPowerUps(missionID, playerID)) {
      dicRnPTaken[pu.itemType] = pu.ableCnt;
    }
    for (final it in fetchedItems) {
      if (dicItemEnd[it.itemID] == null) {
        _store.upsertItemInPlay(MissionItemInPlay(missionID: missionID, playerID: playerID, itemID: it.itemID));
        dicItemEnd[it.itemID] = 'N';
      }
    }

    if (virtualMode) {
      virtualOffsetApplied = VirtualModeManager.applyOffset(m.items, playerLocation, isNewStart: isNewStart);
    } else {
      virtualOffsetApplied = true;
    }

    mission = m;
    items = m.items;
    missionLimitSeconds = m.limitTime;
    missionTimedOut = false;
    remainingMissionTime = m.limitTime.toDouble();
    updateCounters();
    startTimer();
    notifyListeners();
  }

  bool reapplyVirtualOffsetIfNeeded(LatLng? player) {
    if (!isVirtualMode || virtualOffsetApplied) return false;
    final applied = VirtualModeManager.applyOffset(items, player, isNewStart: true);
    if (applied) {
      mission?.items = items;
      virtualOffsetApplied = true;
      notifyListeners();
    }
    return applied;
  }

  // MARK: 타이머
  void startTimer() {
    stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (!missionStarted || missionStartTime == null) return;
    elapsedTime = DateTime.now().difference(missionStartTime!).inMilliseconds / 1000.0;

    if (missionLimitSeconds > 0 && !missionTimedOut && !missionCompleted) {
      remainingMissionTime = missionLimitSeconds - elapsedTime;
      if (remainingMissionTime <= 0) {
        remainingMissionTime = 0;
        missionTimedOut = true;
        stopTimer();
        _sound.play(SoundEffect.timeOver);
        _recordPlay(_PlayAction.fail, DateTime.now());
      }
    }

    if (isTimeOutActive && timeOutStartTime != null) {
      remainingRunTime = timeOutLimitTime - DateTime.now().difference(timeOutStartTime!).inMilliseconds / 1000.0;
      if (remainingRunTime <= 0) _handleRunTimeExpired();
    }
    notifyListeners();
  }

  void _handleRunTimeExpired() {
    final expiredLimit = timeOutLimitTime;
    final startID = activeTimeoutStartID;
    isTimeOutActive = false;
    activeTimeoutStartID = null;
    timeOutStartTime = null;
    remainingRunTime = 0;
    // 만료 시 Run Start 를 미획득으로 되돌려 재획득 허용.
    if (startID != null) {
      dicItemEnd[startID] = 'N';
      _store.upsertItemInPlay(MissionItemInPlay(missionID: missionID, playerID: playerID, itemID: startID, endYN: 'N'));
      _acquisitionOrder.removeWhere((e) => e == startID);
      updateCounters();
    }
    _sound.play(SoundEffect.timeOver);
    _enqueueAlert(ItemAcquiredAlert(title: 'Run End 실패!', message: '제한 시간 $expiredLimit초 초과 — Run Start 를 다시 획득하세요'));
  }

  // MARK: 아이템 획득
  void acquireItem(MissionItem item) {
    final mid = missionID;
    if (mid.isEmpty) return;

    // Run End 사전 검사
    if (item.itemType == ItemType.timeoutEnd) {
      if (!isTimeOutActive) {
        _enqueueAlert(ItemAcquiredAlert(title: '획득 실패', message: 'Run Start 아이템을 먼저 획득하세요.', itemIconName: item.arIconName));
        return;
      }
      if (activeTimeoutStartID != null && item.relationItemID != activeTimeoutStartID) {
        _enqueueAlert(ItemAcquiredAlert(title: '획득 실패', message: 'Run Start 와 Run End 가 짝이 맞아야 합니다.', itemIconName: item.arIconName));
        return;
      }
    }

    dicItemEnd[item.itemID] = 'Y';
    _store.upsertItemInPlay(MissionItemInPlay(
        missionID: mid, playerID: playerID, itemID: item.itemID, endYN: 'Y', endTime: DateTime.now()));

    // 파워업 (radar/defense/solution)
    if (item.itemType.isRadar || item.itemType == ItemType.mineNoBomb || item.itemType == ItemType.solution) {
      dicRnPTaken[item.itemType.code] = (dicRnPTaken[item.itemType.code] ?? 0) + 1;
      _store.upsertPowerUp(ItemRnPInPlay(
          missionID: mid, playerID: playerID, itemType: item.itemType.code, ableCnt: dicRnPTaken[item.itemType.code]!, acquiredTime: DateTime.now()));
      if (item.itemType.isRadar) _sound.play(SoundEffect.radar);
    }

    // Gambling
    MissionItem? randomBonus;
    if (item.itemType == ItemType.random) {
      var candidates = _memoryRandomCandidates(item.itemID);
      if (isTimeOutActive) candidates = candidates.where((c) => c.itemType != ItemType.timeoutStart).toList();
      if (candidates.isNotEmpty) {
        randomBonus = (candidates..shuffle()).first;
        acquireItem(randomBonus);
      }
    }

    // Start
    if (item.itemType == ItemType.start && !missionStarted) {
      missionStarted = true;
      missionStartTime = DateTime.now();
      _store.upsertMissionInPlay(MissionInPlay(missionID: mid, playerID: playerID, startYN: 'Y', startTime: missionStartTime));
      _sound.play(SoundEffect.gogogo);
      _recordPlay(_PlayAction.start, missionStartTime!);
    }

    // Run Start → 타임아웃 시작
    if (item.itemType == ItemType.timeoutStart) {
      timeOutStartTime = DateTime.now();
      final end = items.where((it) => it.itemType == ItemType.timeoutEnd && it.relationItemID == item.itemID).firstOrNull;
      if (end != null) {
        timeOutLimitTime = end.effectiveTime;
        isTimeOutActive = true;
        activeTimeoutStartID = item.itemID;
      }
    }
    // Run End → 타임아웃 종료
    if (item.itemType == ItemType.timeoutEnd) {
      isTimeOutActive = false;
      activeTimeoutStartID = null;
    }

    // End → 완료 검사
    if (item.itemType == ItemType.end) {
      stopTimer();
      if (_isMissionCompletedInMemory) {
        missionCompleted = true;
        isMissionEnd = true;
        _sound.play(SoundEffect.gameFinish);
        _recordPlay(_PlayAction.finish, DateTime.now());
      }
    }

    _acquisitionOrder.add(item.itemID);
    updateCounters();
    if (!missionCompleted) _sound.play(SoundEffect.itemGet);
    _setAcquiredAlert(item, randomBonus);
    notifyListeners();
  }

  // MARK: 지뢰 폭발
  void handleMineBlast(MissionItem item) {
    final mid = missionID;
    if (mid.isEmpty || dicItemEnd[item.itemID] == 'Y') return;
    _haptic.vibrate();
    dicItemEnd[item.itemID] = 'Y';
    _store.upsertItemInPlay(MissionItemInPlay(missionID: mid, playerID: playerID, itemID: item.itemID, endYN: 'Y', endTime: DateTime.now()));
    _sound.play(SoundEffect.explosion);

    // Defense
    final defense = dicRnPTaken[ItemType.mineNoBomb.code] ?? 0;
    if (defense > 0) {
      dicRnPTaken[ItemType.mineNoBomb.code] = defense - 1;
      _store.upsertPowerUp(ItemRnPInPlay(missionID: mid, playerID: playerID, itemType: ItemType.mineNoBomb.code, ableCnt: defense - 1));
      _enqueueAlert(ItemAcquiredAlert(title: '지뢰 폭발!', message: 'Defense 아이템으로 피해를 막았습니다', itemIconName: item.arIconName));
      updateCounters();
      notifyListeners();
      return;
    }

    // 최근 획득 아이템 되돌리기
    String? lostName;
    final lost = _memoryLastAcquiredItem(item.itemID);
    if (lost != null) {
      dicItemEnd[lost.itemID] = 'N';
      _store.upsertItemInPlay(MissionItemInPlay(missionID: mid, playerID: playerID, itemID: lost.itemID, endYN: 'N'));
      _acquisitionOrder.removeWhere((e) => e == lost.itemID);
      lostName = lost.itemType.displayLabel;
      if (lost.itemType == ItemType.start) {
        missionStarted = false;
        missionStartTime = null;
        _store.upsertMissionInPlay(MissionInPlay(missionID: mid, playerID: playerID, startYN: 'N'));
      }
    }
    if (isTimeOutActive) {
      isTimeOutActive = false;
      activeTimeoutStartID = null;
      lostName ??= 'Run Start';
    }
    updateCounters();
    _enqueueAlert(ItemAcquiredAlert(
      title: '지뢰 폭발!',
      message: lostName != null ? '최근 획득한 $lostName 아이템을 잃었습니다.' : '지뢰가 폭발했습니다!',
      itemIconName: item.arIconName,
    ));
    notifyListeners();
  }

  void detectMineProximity(LatLng player) {
    if (!missionStarted || missionCompleted) return;
    for (final it in items) {
      if (it.itemType != ItemType.mine || dicItemEnd[it.itemID] == 'Y') continue;
      if (_distance(player, it.coordinate) <= it.rangeAR) {
        handleMineBlast(it);
        return;
      }
    }
  }

  // MARK: 알림 큐
  void _enqueueAlert(ItemAcquiredAlert a, {bool prepend = false}) {
    if (prepend && pendingAlert != null) {
      _alertQueue.insert(0, pendingAlert!);
      pendingAlert = a;
    } else if (pendingAlert == null) {
      pendingAlert = a;
    } else {
      _alertQueue.add(a);
    }
  }

  void dismissCurrentAlert() {
    if (_alertQueue.isEmpty) {
      pendingAlert = null;
    } else {
      pendingAlert = _alertQueue.removeAt(0);
      _sound.play(SoundEffect.itemGet);
    }
    notifyListeners();
  }

  // MARK: 메모리 헬퍼
  bool get _isMissionCompletedInMemory =>
      items.every((it) => !it.isMandatory || dicItemEnd[it.itemID] == 'Y');

  List<MissionItem> _memoryRandomCandidates(int excludeItemID) => items
      .where((it) =>
          it.itemID != excludeItemID &&
          dicItemEnd[it.itemID] != 'Y' &&
          ![ItemType.end, ItemType.random, ItemType.black].contains(it.itemType))
      .toList();

  MissionItem? _memoryLastAcquiredItem(int excludeItemID) {
    for (final id in _acquisitionOrder.reversed) {
      if (id == excludeItemID) continue;
      final it = items.where((e) => e.itemID == id).firstOrNull;
      if (it == null || dicItemEnd[it.itemID] != 'Y') continue;
      if ([ItemType.mine, ItemType.mineNoBomb, ItemType.random, ItemType.timeoutStart].contains(it.itemType)) continue;
      return it;
    }
    return null;
  }

  // MARK: 퀴즈 페널티
  int quizFailCount(MissionItem item) =>
      _store.fetchItemInPlay(missionID, playerID, item.itemID)?.failCnt ?? 0;

  void recordQuizFailure(MissionItem item, int quizSeq) {
    final cur = _store.fetchItemInPlay(missionID, playerID, item.itemID);
    _store.upsertItemInPlay(MissionItemInPlay(
      missionID: missionID, playerID: playerID, itemID: item.itemID,
      endYN: 'N', failCnt: (cur?.failCnt ?? 0) + 1, quizSeq: quizSeq, endTime: DateTime.now(),
    ));
  }

  // MARK: 카운터
  void updateCounters() {
    final hasRadarMap = dicRnPTaken.containsKey(ItemType.radarMap.code);
    final hasRadarAR = dicRnPTaken.containsKey(ItemType.radarAR.code);
    final hasRadarAll = dicRnPTaken.containsKey(ItemType.radarAll.code);
    final hasRadarMine = dicRnPTaken.containsKey(ItemType.radarMine.code);
    mineCount = mandatoryRemaining = hiddenOnMapCount = stealthOnARCount = 0;
    for (final it in items) {
      if (dicItemEnd[it.itemID] == 'Y') continue;
      if (it.itemType == ItemType.mine && !hasRadarMine) mineCount++;
      if (it.isMandatory) mandatoryRemaining++;
      if (!it.showType.isVisibleOnMap(hasRadarMap: hasRadarMap, hasRadarAll: hasRadarAll)) hiddenOnMapCount++;
      if (!it.showType.isVisibleInAR(hasRadarAR: hasRadarAR, hasRadarAll: hasRadarAll)) stealthOnARCount++;
    }
  }

  // MARK: 가시성
  bool shouldShowOnMap(MissionItem item) {
    if (!missionStarted && item.itemType != ItemType.start) return false;
    if (item.itemType == ItemType.end && mandatoryRemaining > 1) return false;
    final hasRadarMap = dicRnPTaken.containsKey(ItemType.radarMap.code);
    final hasRadarAll = dicRnPTaken.containsKey(ItemType.radarAll.code);
    final hasRadarMine = dicRnPTaken.containsKey(ItemType.radarMine.code);
    if (item.itemType == ItemType.mine) return hasRadarMine;
    if (item.itemType == ItemType.black) return false; // 원 오버레이만
    if (item.itemType != ItemType.start &&
        item.itemType != ItemType.black &&
        dicItemEnd[item.itemID] != 'Y' &&
        _isInsideUnacquiredDarkZone(item)) {
      return false;
    }
    if (dicItemEnd[item.itemID] == 'Y') return true;
    return item.showType.isVisibleOnMap(hasRadarMap: hasRadarMap, hasRadarAll: hasRadarAll);
  }

  bool _isInsideUnacquiredDarkZone(MissionItem item) {
    for (final b in items) {
      if (b.itemType != ItemType.black || dicItemEnd[b.itemID] == 'Y') continue;
      if (_distance(b.coordinate, item.coordinate) <= b.rangeAR) return true;
    }
    return false;
  }

  // MARK: 획득 팝업 문구
  void _setAcquiredAlert(MissionItem item, MissionItem? bonus) {
    final icon = item.arIconName;
    switch (item.itemType) {
      case ItemType.start:
        _enqueueAlert(ItemAcquiredAlert(title: 'Start Item!', message: item.info.isEmpty ? '미션을 시작합니다' : item.info, itemIconName: icon));
      case ItemType.simple:
        if (item.itemGame == 0) {
          _enqueueAlert(ItemAcquiredAlert(title: 'Hint!', message: item.info.isEmpty ? '힌트' : item.info, itemIconName: icon));
        }
      case ItemType.timeoutStart:
        final limit = items.where((it) => it.itemType == ItemType.timeoutEnd && it.relationItemID == item.itemID).firstOrNull?.effectiveTime ?? timeOutLimitTime;
        _enqueueAlert(ItemAcquiredAlert(title: 'Run Start!', message: '제한 시간 $limit초 안에 Run End 를 획득하세요.', itemIconName: icon));
      case ItemType.timeoutEnd:
        _enqueueAlert(ItemAcquiredAlert(title: 'Run End!', message: item.info.isEmpty ? '타임어택 성공!' : item.info, itemIconName: icon));
      case ItemType.solution:
        _enqueueAlert(ItemAcquiredAlert(title: 'Solution!', message: '퀴즈 정답을 확인할 수 있어요', itemIconName: icon));
      case ItemType.radarAR:
        _enqueueAlert(ItemAcquiredAlert(title: 'Stealth Radar!', message: 'AR 에서 스텔스 아이템이 보입니다', itemIconName: icon));
      case ItemType.radarMap:
        _enqueueAlert(ItemAcquiredAlert(title: 'Map Radar!', message: '지도에서 숨은 아이템이 보입니다', itemIconName: icon));
      case ItemType.radarMine:
        _enqueueAlert(ItemAcquiredAlert(title: 'Mine Radar!', message: '지도에 지뢰가 표시됩니다', itemIconName: icon));
      case ItemType.radarAll:
        _enqueueAlert(ItemAcquiredAlert(title: 'All Radar!', message: '모든 숨은 아이템이 보입니다', itemIconName: icon));
      case ItemType.mineNoBomb:
        _enqueueAlert(ItemAcquiredAlert(title: 'Defense!', message: '지뢰 피해를 1번 막아줍니다', itemIconName: icon));
      case ItemType.coupon:
        _enqueueAlert(ItemAcquiredAlert(title: 'Coupon!', message: item.info.isEmpty ? '쿠폰 획득' : item.info, itemIconName: icon));
      case ItemType.random:
        _enqueueAlert(
          ItemAcquiredAlert(title: 'Gambling!', message: bonus != null ? '획득: ${bonus.itemType.displayLabel}!' : '꽝! 남은 아이템 없음', itemIconName: icon),
          prepend: true,
        );
      default:
        break;
    }
  }

  // MARK: 서버 기록
  void _recordPlay(_PlayAction action, DateTime time) {
    final mid = mission?.id;
    if (mid == null) return;
    final start = missionStartTime ?? time;
    switch (action) {
      case _PlayAction.start:
        _ds.recordPlayStart(missionID: mid, playerID: playerID, startTime: time, isVirtual: isVirtualMode);
      case _PlayAction.finish:
        _ds.recordPlayFinish(missionID: mid, playerID: playerID, startTime: start, endTime: time, isVirtual: isVirtualMode);
      case _PlayAction.fail:
        _ds.recordPlayFail(missionID: mid, playerID: playerID, startTime: start, endTime: time, isVirtual: isVirtualMode);
    }
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}

enum _PlayAction { start, finish, fail }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
