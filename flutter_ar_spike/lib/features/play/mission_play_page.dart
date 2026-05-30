// features/play/mission_play_page.dart — 맵 플레이 호스트.
// SwiftUI MissionPlayView 이식. 맵 화면이 항상 base, 하단 카메라 버튼이 AR 풀스크린 라우트를 push.
// 핀 탭은 callout(아이템 정보) 표시 — 획득 절대 X (모든 획득은 AR 에서).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  final MapController _mapCtrl = MapController();
  LatLng? _player;
  StreamSubscription<Position>? _posSub;
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

  // 아이템 획득 라우팅: 퀴즈→QuizView, 미니게임→MiniGameView, 그 외 직접. (AR 에서만 호출됨)
  Future<void> _requestAcquire(MissionItem it) async {
    if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
      final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => QuizView(item: it, engine: _engine)));
      if (ok == true) _engine.acquireItem(it);
    } else if (it.itemType == ItemType.simple && it.itemGame > 0) {
      // SwiftUI MiniGameView 가 acquireItem 을 내부에서 직접 호출 + hintReveal 오버레이 표시 →
      // 여기서는 단순히 화면을 띄우기만 하면 됨. (중복 acquire 방지)
      await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => MiniGameView(item: it, engine: _engine)));
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
    if (!_endShown && (_engine.missionCompleted || _engine.missionTimedOut)) {
      _endShown = true;
      final done = _engine.missionCompleted;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (ctx) => done
              // SwiftUI MissionCompletePopup — 별점 + 후기 입력.
              ? MissionCompletePopup(
                  onSubmit: (score, reply) async {
                    if (score >= 1 && _engine.mission != null) {
                      final ds = ref.read(dataSourceProvider);
                      final uid = ref.read(authSessionProvider).userId ?? 'guest';
                      await ds.submitReview(
                        missionID: _engine.mission!.id,
                        userID: uid,
                        score: score.toDouble(),
                        reply: reply,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) Navigator.pop(context);
                  },
                  onSkip: () {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) Navigator.pop(context);
                  },
                )
              // 시간초과 — 단순 결과 팝업.
              : MissionResultPopup(
                  success: false,
                  elapsedText: hmsString(_engine.elapsedTime.toInt()),
                  onClose: () { Navigator.pop(ctx); Navigator.pop(context); },
                ),
        );
      });
    }
  }

  int get _timerSeconds {
    if (_engine.isTimeOutActive) return _engine.remainingRunTime.clamp(0, 1 << 31).toInt();
    if (_engine.missionLimitSeconds > 0) return _engine.remainingMissionTime.clamp(0, 1 << 31).toInt();
    return _engine.elapsedTime.toInt();
  }

  bool get _warning =>
      (_engine.isTimeOutActive && _engine.remainingRunTime < 10) ||
      (_engine.missionLimitSeconds > 0 && !_engine.isTimeOutActive && _engine.remainingMissionTime < 10);

  void _recenter() {
    if (_player != null) _mapCtrl.move(_player!, 17);
  }

  void _showInfo() {
    final done = _engine.items.where((it) => _engine.dicItemEnd[it.itemID] == 'Y').length;
    final total = _engine.items.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mission Info', style: TextStyle(fontFamily: DuoFonts.display)),
        content: Text('Items: $done / $total\nMode: ${widget.virtual ? 'Virtual' : 'Real'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  // 핀 탭 — 아이템 정보(callout) 바텀시트. 획득 버튼 없음 — AR 에서만 획득.
  void _showItemCallout(MissionItem it) {
    final acquired = _engine.dicItemEnd[it.itemID] == 'Y';
    final dist = _player != null
        ? const Distance()(_player!, it.coordinate).toStringAsFixed(0)
        : '—';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Image.asset(it.mapIconName, width: 44, height: 44,
                  errorBuilder: (_, _, _) => const Icon(Icons.place, size: 40, color: DuoColors.green500)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.itemType.displayLabel,
                      style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 20, color: DuoColors.eel2)),
                  Text(
                    [
                      if (it.isMandatory) '필수',
                      '거리 ${dist}m',
                      '반경 ${it.rangeAR}m',
                      if (acquired) '획득 완료',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: DuoColors.hare),
                  ),
                ]),
              ),
            ]),
            if (it.info.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(it.info, style: const TextStyle(fontSize: 14, color: DuoColors.wolf2)),
            ],
            const SizedBox(height: 14),
            const Text('획득은 AR 모드에서만 — 하단 카메라 버튼을 눌러 AR 화면으로 이동하세요.',
                style: TextStyle(fontSize: 12, color: DuoColors.hare)),
          ]),
        ),
      ),
    );
  }

  Future<void> _openAR() async {
    // SwiftUI 1:1 — 흔들기/탭 시 AR 이 닫히고 (motion 리스너 dispose) 부모가 라우팅한다.
    // AR 위에 미니게임/퀴즈를 올리지 않으므로 진행 중 다른 아이템이 자동 획득되는 일이 없음.
    final tapped = await Navigator.of(context).push<MissionItem?>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ArPlay(engine: _engine, playerProvider: () => _player),
    ));
    if (tapped != null && mounted) await _requestAcquire(tapped);
  }

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
          child: MapPlay(
            engine: _engine,
            player: _player,
            controller: _mapCtrl,
            onPinTap: _showItemCallout,
          ),
        ),
        // 상단: 닫기 + 타이머 + recenter + info(?) — SwiftUI LegacyTopChrome 이식.
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                _circleBtn(Icons.close, () => Navigator.pop(context)),
                const Spacer(),
                WhitePillTimer(seconds: _timerSeconds, warning: _warning),
                const Spacer(),
                _circleBtn(Icons.gps_fixed, _recenter),
                const SizedBox(width: 6),
                _circleBtn(Icons.help_outline, _showInfo, tint: DuoColors.macaw, fg: Colors.white),
              ]),
            ),
          ),
        ),
        // 하단 HUD — SwiftUI LegacyBottomBar: 4 chip + 부유 카메라 (AR 진입).
        Positioned(
          left: 14, right: 14, bottom: 18,
          child: MapBottomBar(
            mineCount: _engine.mineCount,
            mandatoryRemaining: _engine.mandatoryRemaining,
            hiddenCount: _engine.hiddenOnMapCount,
            stealthCount: _engine.stealthOnARCount,
            onCamera: _openAR,
          ),
        ),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color tint = Colors.white, Color fg = DuoColors.eel2}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: fg),
        ),
      );
}
