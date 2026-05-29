// features/play/mission_play_page.dart — 플레이 호스트 (Map/AR 탭 + 타이머 + HUD + 알림).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/play_hud.dart';
import '../../game/game_engine.dart';
import '../../game/play_state_store.dart';
import '../../models/item_type.dart';
import '../../models/mission.dart';
import '../../models/mission_item.dart';
import '../../models/parse_utils.dart';
import '../../network/app_config.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import 'ar_play.dart';
import 'map_play.dart';
import 'minigame_view.dart';
import 'popups.dart';
import 'quiz_view.dart';

class MissionPlayPage extends ConsumerStatefulWidget {
  final Mission mission;
  final bool virtual;
  const MissionPlayPage({super.key, required this.mission, required this.virtual});

  @override
  ConsumerState<MissionPlayPage> createState() => _MissionPlayPageState();
}

class _MissionPlayPageState extends ConsumerState<MissionPlayPage> {
  late final GameEngine _engine;
  LatLng? _player;
  StreamSubscription<Position>? _posSub;
  int _tab = 0; // 0 map, 1 ar
  bool _ready = false;
  bool _alertShowing = false;
  bool _endShown = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(
      dataSource: ref.read(dataSourceProvider),
      playState: PlayStateStore(),
      soundService: SoundService(),
      hapticService: HapticService(),
      playerID: ref.read(authSessionProvider).userId ?? 'guest',
    );
    _engine.addListener(_onEngine);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await ref.read(authBootstrapProvider).ensureAuthenticated();
    _player = await _currentLatLng();
    await _engine.setup(
      missionID: widget.mission.id,
      isNewStart: true,
      virtualMode: widget.virtual,
      playerLocation: _player,
    );
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1),
    ).listen((p) {
      _player = LatLng(p.latitude, p.longitude);
      _engine.reapplyVirtualOffsetIfNeeded(_player);
      _engine.detectMineProximity(_player!);
      if (mounted) setState(() {});
    });
    if (mounted) setState(() => _ready = true);
  }

  // 아이템 획득 라우팅: 퀴즈→QuizView, 미니게임→MiniGameView, 그 외 직접.
  Future<void> _requestAcquire(MissionItem it) async {
    if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
      final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => QuizView(item: it, engine: _engine)));
      if (ok == true) _engine.acquireItem(it);
    } else if (it.itemType == ItemType.simple && it.itemGame > 0) {
      final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => MiniGameView(item: it)));
      if (ok == true) _engine.acquireItem(it);
    } else {
      _engine.acquireItem(it);
    }
  }

  Future<LatLng?> _currentLatLng() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final p = await Geolocator.getCurrentPosition();
        return LatLng(p.latitude, p.longitude);
      }
    } catch (_) {}
    return null;
  }

  void _onEngine() {
    if (!mounted) return;
    setState(() {});
    // 알림 팝업 (Phase 8 에서 ItemAcquiredPopup V2 로 교체).
    if (_engine.pendingAlert != null && !_alertShowing) {
      _alertShowing = true;
      final a = _engine.pendingAlert!;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => ItemAcquiredPopup(alert: a, onOK: () => Navigator.pop(ctx)),
      ).then((_) {
        _alertShowing = false;
        _engine.dismissCurrentAlert();
      });
    }
    // 종료(완료/타임아웃)
    if (!_endShown && (_engine.missionCompleted || _engine.missionTimedOut)) {
      _endShown = true;
      final done = _engine.missionCompleted;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (ctx) => MissionResultPopup(
            success: done,
            elapsedText: hmsString(_engine.elapsedTime.toInt()),
            onClose: () { Navigator.pop(ctx); Navigator.pop(context); },
          ),
        );
      });
    }
  }

  int get _arSeconds {
    if (_engine.isTimeOutActive) return _engine.remainingRunTime.clamp(0, 1 << 31).toInt();
    if (_engine.missionLimitSeconds > 0) return _engine.remainingMissionTime.clamp(0, 1 << 31).toInt();
    return _engine.elapsedTime.toInt();
  }

  bool get _warning =>
      (_engine.isTimeOutActive && _engine.remainingRunTime < 10) ||
      (_engine.missionLimitSeconds > 0 && !_engine.isTimeOutActive && _engine.remainingMissionTime < 10);

  @override
  void dispose() {
    _posSub?.cancel();
    _engine.removeListener(_onEngine);
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: _tab == 0
              ? MapPlay(engine: _engine, player: _player, onAcquire: _requestAcquire)
              : ArPlay(engine: _engine, player: _player, onAcquire: _requestAcquire),
        ),
        // 상단: 나가기 + 타이머 + 탭 전환
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _circleBtn(Icons.close, () => Navigator.pop(context)),
              const Spacer(),
              WhitePillTimer(seconds: _arSeconds, warning: _warning),
              const Spacer(),
              _circleBtn(_tab == 0 ? Icons.camera_alt : Icons.map, () => setState(() => _tab = _tab == 0 ? 1 : 0)),
            ]),
          ),
        ),
        // 하단 HUD
        Positioned(
          left: 14, right: 14, bottom: 18,
          child: RadarPillHUD(
            leftLabel: '필수',
            leftValue: '${_engine.mandatoryRemaining}개',
            rightLabel: '지뢰',
            rightValue: '${_engine.mineCount}개',
            radar: const RadarDisc(),
          ),
        ),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: DuoColors.eel2),
        ),
      );
}
