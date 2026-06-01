// features/play/minigame_view.dart — SwiftUI MiniGameView.swift 이식 (흔들기/탭 진행도).
// 디자인: 검정 bg + 일러스트(shake_0/shake_1 토글 ±6°) + "PLAY SPOT" 노란 wordmark + 진행도 X/100 +
//        하단 RadarPillHUD + 부유 레이더 + 진행도 > 50% 시 노란 halo.
// 모드: item.itemGame == 1 → 흔들기, 2 → 탭 (시뮬레이터 폴백: 흔들기 모드도 탭으로 진행).
// 사운드: shake 마다 gameTouch, 완료 시 gameFinish + success 햅틱.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/web_shake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:sensors_plus/sensors_plus.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/play_hud.dart';
import '../../game/game_engine.dart';
import '../../models/mission_item.dart';
import '../../services/sound_service.dart';
import '../../design_system/candy_button.dart';

class MiniGameView extends StatefulWidget {
  final MissionItem item;
  final GameEngine engine;
  const MiniGameView({super.key, required this.item, required this.engine});

  @override
  State<MiniGameView> createState() => _MiniGameViewState();
}

class _MiniGameViewState extends State<MiniGameView> {
  static const _tickInterval = Duration(milliseconds: 100);
  static const _shakeGain = 15.0; // SwiftUI 동일
  static const _decayPerTick = 0.4;
  static const _shakeThreshold = 14.0; // 1.4G ≈ 13.7 m/s²
  static const _shakeCooldown = Duration(milliseconds: 120);

  double _progress = 0;
  bool _won = false;
  int _frame = 0; // shake_0/shake_1 토글
  int _tickCount = 0;
  Timer? _tick;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<double>? _webShakeSub;
  WebShake? _webShake;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  final _sound = SoundService();

  bool get _isShakeMode => widget.item.itemGame == 1;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(_tickInterval, _onTick);
    if (_isShakeMode) {
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
            _addProgress();
          });
        });
      } else {
        _accelSub = userAccelerometerEventStream().listen(_onAccel);
      }
    }
  }

  void _onTick(Timer _) {
    _tickCount++;
    setState(() {
      if (_progress > 0) _progress = (_progress - _decayPerTick).clamp(0.0, 100.0);
      // 일러스트 프레임 토글 — 3 tick(0.3s) 마다 (SwiftUI: line 217).
      if (_tickCount % 3 == 0) _frame = 1 - _frame;
      // 상단 타이머는 engine 의 _timerSeconds 를 100ms 마다 재평가 (별도 카운터 없음).
    });
  }

  /// Map/AR Play 와 동일 — Run 타임 > 미션 제한 > 경과.
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

  void _onAccel(UserAccelerometerEvent e) {
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (mag < _shakeThreshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < _shakeCooldown) return;
    _lastShake = now;
    _addProgress();
  }

  void _addProgress() {
    if (_won) return;
    setState(() => _progress = (_progress + _shakeGain).clamp(0.0, 100.0));
    _sound.play(SoundEffect.gameTouch);
    if (_progress >= 100) _win();
  }

  /// SwiftUI MiniGameView.swift:222-228 `checkCompletion` 1:1 이식.
  /// engine.acquireItem 을 *MiniGameView 안에서* 호출 + 힌트 공개 오버레이 표시 (pop 안 함).
  void _win() {
    _won = true;
    _tick?.cancel();
    _accelSub?.cancel();
    _webShakeSub?.cancel();
    _webShake?.stop();
    _sound.play(SoundEffect.gameFinish);
    HapticFeedback.heavyImpact();
    widget.engine.acquireItem(widget.item);
    setState(() {}); // _won=true 반영해 _HintRevealOverlay 노출
  }

  @override
  void dispose() {
    _tick?.cancel();
    _accelSub?.cancel();
    _webShakeSub?.cancel();
    _webShake?.stop();
    _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _progress > 50 ? DuoColors.bee.withValues(alpha: 0.4) : Colors.transparent;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _addProgress, // 시뮬/웹 폴백 + 탭 모드.
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(children: [
            // 상단: map(좌) + 흰 타이머 pill.
            Positioned(
              top: 8, left: 14, right: 14,
              child: Row(children: [
                _candyBtn(Icons.map, () => Navigator.pop(context, false), tint: DuoColors.green500, fg: Colors.white),
                const Spacer(),
                WhitePillTimer(seconds: _timerSeconds, warning: _warning),
                const Spacer(),
                const SizedBox(width: 44),
              ]),
            ),
            // 중앙: PLAY SPOT 워드마크(뒤) + 일러스트(앞) + halo + sparkles. SwiftUI z-order 일치.
            Center(
              child: SizedBox(
                width: 360, height: 360,
                child: Stack(alignment: Alignment.center, children: [
                  // (1) Halo glow — 흔들기 시작부터 부드럽게 부풀어남 (progress 비례).
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 320, height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [progressColor, Colors.transparent]),
                    ),
                  ),
                  // (2) PLAY SPOT 워드마크 — 회색 outline + 녹색 그라데이션이 하단→상단으로 차오름.
                  _PlaySpotWordmark(progress: _progress / 100),
                  // (3) Sparkles — 흔들기 모드에서 진행 중일 때만.
                  if (_isShakeMode && _progress > 0 && _progress < 100) const _SparkleStars(),
                  // (4) 일러스트 — 앞에 (워드마크를 가림).
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: (_isShakeMode ? (_frame == 0 ? -0.0167 : 0.0167) : 0), // ±6°
                    child: Image.asset(
                      'assets/minigame/${_isShakeMode ? 'shake' : 'touch'}_$_frame.png',
                      width: 220, height: 220,
                      errorBuilder: (_, _, _) => Container(
                        width: 220, height: 220,
                        decoration: BoxDecoration(color: DuoColors.swan2, borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.touch_app, size: 80, color: DuoColors.eel2),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            // 하단 라벨 + X/100.
            Positioned(
              left: 0, right: 0, bottom: 110,
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Text(_isShakeMode ? '흔드세요!' : '터치하세요!',
                      style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 26, color: Colors.white)),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('${_progress.toInt()}',
                        style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 32, color: DuoColors.bee)),
                    const Text(' / 100',
                        style: TextStyle(fontFamily: DuoFonts.display, fontSize: 24, color: DuoColors.swan)),
                  ]),
                ]),
              ]),
            ),
            // 하단 RadarPillHUD — HINT/0m | 부유 레이더 | 유효 반경/100m.
            Positioned(
              left: 14, right: 14, bottom: 18,
              child: RadarPillHUD(
                leftLabel: 'HINT',
                leftValue: '0m',
                rightLabel: '유효 반경',
                rightValue: '100m',
                radar: const BearingRadarDisc(headingDegrees: 0),
              ),
            ),
            // (last) 힌트 공개 오버레이 — SwiftUI MiniGameView.swift:171-192 hintRevealOverlay.
            // _win() 직후 표시. OK 누르면 MiniGameView 닫힘.
            if (_won) _HintRevealOverlay(
              item: widget.item,
              onOK: () => Navigator.pop(context, true),
            ),
          ]),
        ),
      ),
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

/// "PLAY SPOT" wordmark — SwiftUI `WordmarkPlaySpot.swift` outline variant 1:1 이식.
/// 같은 PNG (`playspot_logo.png`) 를 두 번 합성:
///   (a) 베이스 — saturation 0 + 어둡게 + opacity 0.55 (아직 안 채워진 부분)
///   (b) 채움 — duoGreen 그라데이션을 PNG alpha 로 마스킹 + 하단부터 progress 만큼 reveal
///   (c) >50% 부터 노란 bee glow + green400 glow
class _PlaySpotWordmark extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  const _PlaySpotWordmark({required this.progress});

  // saturation 0 + brightness -0.35 (lumi 행렬 + offset).
  static const _darkenGray = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, -90,
    0.2126, 0.7152, 0.0722, 0, -90,
    0.2126, 0.7152, 0.0722, 0, -90,
    0,      0,      0,      1,   0,
  ]);

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final glow = math.max(0.0, (p - 0.5) * 2.0); // 50% 이후 0→1
    const asset = AssetImage('assets/minigame/playspot_logo.png');

    // SwiftUI: .frame(width: wordmarkW, height: wordmarkW * 0.75) — 4:3 비율.
    // illustrationSide = 220 → wordmarkW = min(screenW, 220*1.45) = 319, height = 239.
    return SizedBox(
      width: 320, height: 240,
      child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // (a) 베이스: 어둡게 처리한 회색 로고. BoxFit.contain 으로 SizedBox 안에 맞춰짐.
            const Positioned.fill(
              child: ColorFiltered(
                colorFilter: _darkenGray,
                child: Opacity(opacity: 0.55, child: Image(image: asset, fit: BoxFit.contain)),
              ),
            ),
            // (b) 채움: ClipRect 로 하단 p% 만 보임, 그 안에서 그라데이션 + 로고 alpha 마스킹.
            //   ShaderMask(blendMode=srcIn) 의 효과: shader 가 자식(logo)의 alpha 영역에만 그려짐
            //   → SwiftUI 의 `LinearGradient.mask { logoShape }` 와 동등.
            Positioned.fill(
              child: ClipRect(
                clipper: _BottomProgressClipper(p: p),
                child: DecoratedBox(
                  decoration: BoxDecoration(boxShadow: glow > 0
                      ? [
                          BoxShadow(color: DuoColors.bee.withValues(alpha: 0.6 * glow), blurRadius: 18 * glow),
                          BoxShadow(color: DuoColors.fox.withValues(alpha: 0.4 * glow), blurRadius: 32 * glow),
                        ]
                      : const []),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [DuoColors.foxDeep, DuoColors.fox, DuoColors.bee],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    ).createShader(rect),
                    child: const Image(image: asset, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

/// 하단 progress 비율만큼만 보이게 잘라내는 clipper (SwiftUI `mask(alignment:.bottom){ Rectangle(height: h*p) }`).
class _BottomProgressClipper extends CustomClipper<Rect> {
  final double p;
  _BottomProgressClipper({required this.p});
  @override
  Rect getClip(Size size) {
    final h = size.height * p;
    return Rect.fromLTWH(0, size.height - h, size.width, h);
  }

  @override
  bool shouldReclip(covariant _BottomProgressClipper old) => old.p != p;
}

/// SwiftUI MiniGameView.swift:171-192 hintRevealOverlay 이식.
/// 검정 75% dim + 어두운 카드(eel2) + 아이템 핀 + "Hint Revealed" kicker + info + 주황 OK.
class _HintRevealOverlay extends StatelessWidget {
  final MissionItem item;
  final VoidCallback onOK;
  const _HintRevealOverlay({required this.item, required this.onOK});

  String get _hintText {
    final t = item.info.trim();
    return t.isEmpty ? '(이 힌트는 비어 있습니다)' : t;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DuoColors.eel2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 아이템 핀 (56pt, active + glow).
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DuoColors.green500,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: DuoColors.bee.withValues(alpha: 0.6), blurRadius: 14)],
                ),
                child: Image.asset(item.arIconName, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.lightbulb, color: Colors.white, size: 28)),
              ),
              const SizedBox(height: 14),
              // "HINT REVEALED" kicker (bee yellow).
              const Text('HINT REVEALED', style: TextStyle(
                  fontFamily: DuoFonts.display, fontSize: 12, color: DuoColors.bee, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              // 힌트 본문.
              Text(_hintText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              // 주황 OK 버튼.
              CandyButton(label: '확인 · OK', tint: DuoColors.fox, shadowColor: DuoColors.foxDeep, onPressed: onOK),
            ]),
          ),
        ),
      ),
    );
  }
}

/// SwiftUI MiniGameView 의 SparkleBurst — 일러스트 주변에 흩어진 별 6개(주황/녹색).
/// 단순 정적 배치 + opacity 미세 펄스로 SwiftUI 의 burst 트리거를 근사.
class _SparkleStars extends StatefulWidget {
  const _SparkleStars();

  @override
  State<_SparkleStars> createState() => _SparkleStarsState();
}

class _SparkleStarsState extends State<_SparkleStars> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  // (dx, dy, color, size) — 일러스트(220×220) 주변에 6개.
  static const _stars = [
    (-110.0, -60.0, DuoColors.fox, 28.0),
    (110.0, -90.0, DuoColors.green500, 22.0),
    (130.0, 30.0, DuoColors.fox, 18.0),
    (-130.0, 40.0, DuoColors.green500, 26.0),
    (-90.0, 130.0, DuoColors.fox, 16.0),
    (110.0, 130.0, DuoColors.green500, 20.0),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return SizedBox(
          width: 360, height: 360,
          child: Stack(children: [
            for (var i = 0; i < _stars.length; i++)
              Positioned(
                left: 180 + _stars[i].$1 - _stars[i].$4 / 2,
                top: 180 + _stars[i].$2 - _stars[i].$4 / 2,
                child: Opacity(
                  opacity: 0.65 + 0.35 * (((_c.value + i / _stars.length) % 1.0) * 2 - 1).abs(),
                  child: CustomPaint(
                    size: Size.square(_stars[i].$4),
                    painter: _StarOutlinePainter(color: _stars[i].$3),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _StarOutlinePainter extends CustomPainter {
  final Color color;
  _StarOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = Path();
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / points;
      final pt = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _) => false;
}
