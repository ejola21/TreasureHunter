// features/play/ar_play.dart — AR 플레이 (카메라 + viewport 게이트 + 단일 아이템 + 베어링 레이더).
// SwiftUI ARGameView 디테일 이식:
//   - 가장 가까운 후보(`nearestCandidateItem`) 가 viewport(±0.25 rad ≈ ±14.3°) 안에 있을 때만 그림.
//   - 아이템 화면 X 위치 = 화면 중앙 + (상대 azimuth / 0.5 rad) × 반폭.
//   - 거리 스케일 = max(0.3, 1.0 - min(d, 500)/500 × 0.7).
//   - 하단 RadarPillHUD + BearingRadarDisc (north-up, 폰 부채꼴 + 절대 아이템 바늘).
//   - 도움말 오버레이 = SwiftUI ARHelpOverlay (말풍선 + kicker + 레이더 범례).
import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sensors_plus/sensors_plus.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/play_hud.dart';
import '../../game/game_engine.dart';
import '../../models/item_type.dart';
import '../../models/mission_item.dart';
import '../../services/web_compass.dart';
import '../../services/web_shake.dart';
import 'ar_item_billboard.dart';

const _dist = Distance();
const _viewportHalfRadians = 0.25; // SwiftUI viewportWidthRadians/2 = 0.25
const _maxScaleDistance = 500.0;

class ArPlay extends StatefulWidget {
  final GameEngine engine;
  /// 호스트(맵 페이지) 의 최신 플레이어 위치를 빌드 시점마다 조회. 매 setState 마다 갱신됨.
  final LatLng? Function() playerProvider;
  const ArPlay({
    super.key,
    required this.engine,
    required this.playerProvider,
  });

  @override
  State<ArPlay> createState() => _ArPlayState();
}

class _ArPlayState extends State<ArPlay> {
  CameraController? _cam;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<double>? _webCompassSub;
  WebCompass? _webCompass;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<double>? _webShakeSub;
  WebShake? _webShake;
  double _heading = 0.0; // 도, 절대(시계방향 from N). 폴백 = 0(=북).
  bool _hasHeading = false;
  bool _showHelp = false;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  // SwiftUI: 1.4G ≈ 13.7 m/s², 쿨다운 500ms (ARGameView.swift:24, MotionService.swift:17)
  static const _shakeThreshold = 14.0;
  static const _shakeCooldown = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onEngine);
    _initCamera();
    _initCompass();
    _initShake();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final ctrl = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (mounted) setState(() => _cam = ctrl);
    } catch (_) {/* 카메라 없음 → 검은 배경 */}
  }

  void _initCompass() {
    if (kIsWeb) {
      // 웹: DeviceOrientationEvent JS interop. iOS Safari 는 사전 권한 요청 후 시작.
      _webCompass = WebCompass();
      WebCompass.requestPermission().then((granted) {
        if (!granted || !mounted) return;
        _webCompass!.start();
        _webCompassSub = _webCompass!.headingStream.listen((h) {
          if (!mounted) return;
          setState(() {
            _heading = (h + 360.0) % 360.0;
            _hasHeading = true;
          });
        });
      });
      return;
    }
    _compassSub = FlutterCompass.events?.listen((e) {
      if (!mounted || e.heading == null) return;
      setState(() {
        _heading = (e.heading! + 360.0) % 360.0;
        _hasHeading = true;
      });
    });
  }

  /// 흔들기 감지 — SwiftUI MotionService 의 isShaking + ARGameView.handleShake 동등.
  /// userAccelerometer (중력 제거된 가속도, m/s²) 의 크기가 1.4G 이상 + 0.5s 쿨다운.
  void _initShake() {
    if (kIsWeb) {
      // 웹: DeviceMotionEvent JS interop (sensors_plus 미지원 대체).
      _webShake = WebShake();
      WebShake.requestPermission().then((granted) {
        if (!granted || !mounted) return;
        _webShake!.start();
        _webShakeSub = _webShake!.magnitudeStream.listen((mag) {
          if (mag < _shakeThreshold) return;
          final now = DateTime.now();
          if (now.difference(_lastShake) < _shakeCooldown) return;
          _lastShake = now;
          _handleShake();
        });
      });
      return;
    }
    _accelSub = userAccelerometerEventStream().listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (mag < _shakeThreshold) return;
      final now = DateTime.now();
      if (now.difference(_lastShake) < _shakeCooldown) return;
      _lastShake = now;
      _handleShake();
    });
  }

  /// SwiftUI ARGameView.handleShake (line 143-156) + onItemTapped 흐름 1:1.
  /// 흔들기 → AR 을 *닫고* 부모(MissionPlayPage) 가 라우팅하도록 아이템을 pop 값으로 반환.
  /// 이렇게 해야 AR 의 motion 리스너가 dispose 되어 미니게임 도중 중복 획득이 생기지 않음.
  bool _acquireFiring = false;
  void _handleShake() {
    if (_acquireFiring) return; // pop 이 진행되는 동안 추가 트리거 차단.
    final c = _visibleItem;
    if (c == null) return;
    final p = widget.playerProvider();
    if (p == null) return;
    if (_dist(p, c.coordinate) > c.rangeAR) return;
    _acquireFiring = true;
    Navigator.of(context).pop(c);
  }

  void _onEngine() {
    if (mounted) setState(() {});
  }

  /// SwiftUI: ARGameView/MissionPlayView 동일 — Run 타임 우선, 미션 제한 시간, 없으면 경과.
  int get _timerSeconds {
    final e = widget.engine;
    if (e.isTimeOutActive) return e.remainingRunTime.clamp(0, 1 << 31).toInt();
    if (e.missionLimitSeconds > 0) return e.remainingMissionTime.clamp(0, 1 << 31).toInt();
    return e.elapsedTime.toInt();
  }

  bool get _warning {
    final e = widget.engine;
    return (e.isTimeOutActive && e.remainingRunTime < 10) ||
        (e.missionLimitSeconds > 0 && !e.isTimeOutActive && e.remainingMissionTime < 10);
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _webCompassSub?.cancel();
    _webCompass?.stop();
    _accelSub?.cancel();
    _webShakeSub?.cancel();
    _webShake?.stop();
    _cam?.dispose();
    widget.engine.removeListener(_onEngine);
    super.dispose();
  }

  // ─── 후보 선정 (SwiftUI nearestCandidateItem 동일 로직) ──────────────────
  /// viewport 검사 없이 가장 가까운 유효 후보. 하단 라벨/레이더 바늘이 이 후보 기반.
  MissionItem? get _nearestCandidate {
    final e = widget.engine;
    final p = widget.playerProvider();
    if (p == null) return null;
    MissionItem? best;
    double bestD = double.maxFinite;
    for (final it in e.items) {
      if (e.dicItemEnd[it.itemID] == 'Y') continue;
      if (!e.missionStarted && it.itemType != ItemType.start) continue;
      if (it.itemType == ItemType.mine || it.itemType == ItemType.black) continue;
      if (it.itemType == ItemType.timeoutStart && e.isTimeOutActive) continue;
      if (it.itemType == ItemType.end && e.mandatoryRemaining > 1) continue;
      final d = _dist(p, it.coordinate);
      if (d < bestD) {
        bestD = d;
        best = it;
      }
    }
    return best;
  }

  /// 아이템 절대 베어링(0°=북, 시계방향) — SwiftUI ARCoordinate.bearing 동일 공식.
  double? _itemBearing(MissionItem it) {
    final p = widget.playerProvider();
    if (p == null) return null;
    final lat1 = p.latitude * math.pi / 180.0;
    final lat2 = it.latitude * math.pi / 180.0;
    final dLon = (it.longitude - p.longitude) * math.pi / 180.0;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final b = math.atan2(y, x) * 180.0 / math.pi;
    return (b + 360.0) % 360.0;
  }

  /// 상대 azimuth(-π~π) — 폰 정면 기준 아이템 방향(라디안).
  double? _relativeAzimuthRad(MissionItem it) {
    final ib = _itemBearing(it);
    if (ib == null) return null;
    final ibRad = ib * math.pi / 180.0;
    final hRad = _heading * math.pi / 180.0;
    double a = ibRad - hRad;
    while (a > math.pi) {
      a -= 2 * math.pi;
    }
    while (a < -math.pi) {
      a += 2 * math.pi;
    }
    return a;
  }

  /// viewport 안에 있는 아이템 (SwiftUI nearestVisibleItem).
  MissionItem? get _visibleItem {
    final c = _nearestCandidate;
    final p = widget.playerProvider();
    if (c == null || p == null) return null;
    if (_dist(p, c.coordinate) > c.rangeAR) return null;
    if (_hasHeading) {
      final rel = _relativeAzimuthRad(c);
      if (rel == null || rel.abs() > _viewportHalfRadians) return null;
    }
    return c;
  }

  /// 화면 X 위치 — heading 있을 때 azimuth 기반, 없으면 중앙.
  double _screenX(MissionItem it, double width) {
    if (!_hasHeading) return width / 2;
    final rel = _relativeAzimuthRad(it);
    if (rel == null) return width / 2;
    return width / 2 + (rel / (_viewportHalfRadians * 2)) * width;
  }

  /// 거리 스케일 — SwiftUI scaleFactor 동일.
  double _scaleFor(MissionItem it) {
    final p = widget.playerProvider();
    if (p == null) return 1.0;
    final d = _dist(p, it.coordinate);
    final s = 1.0 - (math.min(d, _maxScaleDistance) / _maxScaleDistance) * 0.7;
    return math.max(s, 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final candidate = _nearestCandidate;
    final target = _visibleItem;
    final p = widget.playerProvider();
    final dCandidate = (candidate != null && p != null) ? _dist(p, candidate.coordinate).toInt() : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, c) {
        return Stack(children: [
          // 카메라 피드.
          Positioned.fill(
            child: (_cam?.value.isInitialized ?? false)
                ? CameraPreview(_cam!)
                : Container(color: Colors.black),
          ),
          // viewport 내부 아이템만 — 화면 X 는 azimuth, Y 는 중앙(평면 가정), 스케일은 거리.
          // 6 애니메이션(float/sway/pop/pulseRings/conicGlow/sparkles) 은 ARItemBillboard 가 처리.
          if (target != null)
            Positioned(
              left: _screenX(target, c.maxWidth) - 100,
              top: c.maxHeight / 2 - 100,
              width: 200, height: 200,
              child: Transform.scale(
                scale: _scaleFor(target),
                child: ARItemBillboard(
                  item: target,
                  isAcquired: false,
                  onTap: () {
                    if (_acquireFiring) return;
                    final p = widget.playerProvider();
                    final d = p != null ? _dist(p, target.coordinate) : 999.0;
                    if (d > target.rangeAR) return;
                    _acquireFiring = true;
                    Navigator.of(context).pop(target);
                  },
                ),
              ),
            ),
          // 상단: map(좌, 맵 복귀) + WhitePillTimer(가운데, Map Play 와 동일) + ?(우, 도움말).
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(children: [
                  _candyBtn(Icons.map, () => Navigator.pop(context), tint: DuoColors.green500, fg: Colors.white),
                  const Spacer(),
                  WhitePillTimer(seconds: _timerSeconds, warning: _warning),
                  const Spacer(),
                  _candyBtn(Icons.help_outline, () => setState(() => _showHelp = true),
                      tint: DuoColors.macaw, fg: Colors.white),
                ]),
              ),
            ),
          ),
          // 하단 RadarPillHUD — 후보 기반 라벨/거리, 절대 베어링 바늘(north-up).
          Positioned(
            left: 14, right: 14, bottom: 18,
            child: RadarPillHUD(
              leftLabel: candidate?.itemType.displayLabel.toUpperCase() ?? 'HINT',
              leftValue: dCandidate != null ? '${dCandidate}m' : '—',
              rightLabel: candidate != null ? '반경' : '미션 종료!',
              rightValue: candidate != null ? '${candidate.rangeAR}m' : '',
              radar: BearingRadarDisc(
                headingDegrees: _heading,
                itemBearingDegrees: candidate != null ? _itemBearing(candidate) : null,
              ),
            ),
          ),
          if (_showHelp)
            _ARHelpOverlay(
              itemKicker: candidate == null
                  ? 'HINT'
                  : '${candidate.itemType.displayLabel.toUpperCase()}${dCandidate != null ? ' · ${dCandidate}m' : ''}',
              rangeKicker: candidate != null ? '반경 · ${candidate.rangeAR}m' : '반경',
              onClose: () => setState(() => _showHelp = false),
            ),
        ]);
      }),
    );
  }

  Widget _candyBtn(IconData icon, VoidCallback onTap, {Color tint = Colors.white, Color fg = DuoColors.eel2}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: fg),
        ),
      );
}

// ─── 도움말 오버레이 — SwiftUI ARHelpOverlay 이식 ──────────────────────────────
class _ARHelpOverlay extends StatelessWidget {
  final String itemKicker, rangeKicker;
  final VoidCallback onClose;
  const _ARHelpOverlay({required this.itemKicker, required this.rangeKicker, required this.onClose});

  @override
  Widget build(BuildContext context) {
    // SwiftUI ARHelpOverlay 이식. 외곽 dim 50% + 어디 탭해도 닫힘.
    // 모든 말풍선은 intrinsic width (Row+Spacer 로 정렬), Expanded 금지.
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.5),
          child: SafeArea(
            child: Stack(children: [
              // 우상단 X 닫기 — SwiftUI: padding(.top, 36) + padding(.horizontal, 14).
              Positioned(
                top: 36, right: 14,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.close, size: 16, weight: 900, color: DuoColors.eel2),
                  ),
                ),
              ),
              // 메인 콘텐츠 VStack — SwiftUI 의 spacing 16 + padding(.horizontal, 18).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(children: [
                  const SizedBox(height: 92), // SwiftUI capsule.padding(.top, 92)
                  // 화면 설명 pill (Macaw capsule).
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(color: DuoColors.macaw, borderRadius: BorderRadius.circular(999)),
                    child: const Text('화면 설명',
                        style: TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  // Shake 안내 — 좌측, intrinsic width.
                  Row(children: [
                    _Bubble(
                      child: Column(mainAxisSize: MainAxisSize.min, children: const [
                        Text('아이템이 나오면',
                            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 17, color: DuoColors.eel2)),
                        SizedBox(height: 2),
                        Text('Shake it!!',
                            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 28, color: DuoColors.cardinal)),
                      ]),
                    ),
                    const Spacer(),
                  ]),
                  const Spacer(),
                  // 거리 두 개 — IntrinsicHeight + 좌우 정렬, 가운데 Spacer(minLength: 16).
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Bubble(child: _InfoContent(kicker: itemKicker, kickerColor: DuoColors.foxDeep, title: '아이템과 사용자\n간의 거리')),
                      const Spacer(),
                      const SizedBox(width: 16),
                      _Bubble(child: _InfoContent(kicker: rangeKicker, kickerColor: DuoColors.green800, title: '아이템 화면\n표시 거리')),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // 레이더 범례 — 가운데 정렬.
                  _Bubble(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: const [
                      _Kicker(text: '레이더', color: DuoColors.hare),
                      SizedBox(height: 12),
                      _LegendRow(
                        icon: Icon(Icons.arrow_upward, color: DuoColors.bee, size: 22, weight: 900),
                        title: '노란 바늘 · 아이템 방향',
                        sub: 'ITEM',
                      ),
                      SizedBox(height: 8),
                      _LegendRow(icon: _PhoneDisc(), title: '흰색 반경 · 폰 방향', sub: 'PHONE'),
                    ]),
                  ),
                  const SizedBox(height: 120),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 흰 라운드 박스 + 아래쪽 꼬리 삼각형 (SwiftUI bubble).
class _Bubble extends StatelessWidget {
  final Widget child;
  const _Bubble({required this.child});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 7, offset: const Offset(0, 3))],
          ),
          child: child,
        ),
        CustomPaint(painter: _DownTrianglePainter(), size: const Size(20, 11)),
      ]),
    );
  }
}

class _DownTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _) => false;
}

class _InfoContent extends StatelessWidget {
  final String kicker, title;
  final Color kickerColor;
  const _InfoContent({required this.kicker, required this.kickerColor, required this.title});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _Kicker(text: kicker, color: kickerColor),
      const SizedBox(height: 6),
      Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel2)),
    ]);
  }
}

class _Kicker extends StatelessWidget {
  final String text;
  final Color color;
  const _Kicker({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, color: color, letterSpacing: 0.6));
}

class _LegendRow extends StatelessWidget {
  final Widget icon;
  final String title, sub;
  const _LegendRow({required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 34, height: 34, child: Center(child: icon)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel2)),
        Text(sub,
            style: const TextStyle(fontSize: 10, color: DuoColors.hare, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
      ]),
    ]);
  }
}

/// 폰 디스크 아이콘 — 초록 원 + 위로 향한 흰 부채꼴 (레이더 범례용 미니어처).
class _PhoneDisc extends StatelessWidget {
  const _PhoneDisc();
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(28, 28),
        painter: _PhoneDiscPainter(),
      );
}

class _PhoneDiscPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = DuoColors.green500);
    // 위로 향한 흰 부채꼴 (얇은 화살촉).
    final w = size.width * 0.34;
    final p = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx - w, 4)
      ..lineTo(c.dx + w, 4)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _) => false;
}
