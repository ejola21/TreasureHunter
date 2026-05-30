// design_system/play_hud.dart — 플레이 HUD (Map/AR) 디자인 이식.
// SwiftUI MissionPlayView.LegacyBottomBar / ARGameView.radarBar 와 동일 구조:
//   - 맵: 4 stat chip + 가운데 부유 카메라 버튼 (76×76, offset -8).
//   - AR: RadarPillHUD 좌(아이템 라벨/거리) / 부유 레이더(베어링 바늘) / 우(반경 라벨/값).
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'duo_tokens.dart';

String _fmt(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}';
}

/// 상단 흰 pill 타이머 (시계 아이콘 + 디지트, 경고 시 빨강).
class WhitePillTimer extends StatelessWidget {
  final int seconds;
  final bool warning;
  const WhitePillTimer({super.key, required this.seconds, this.warning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.schedule, size: 20, color: warning ? DuoColors.cardinal : DuoColors.fox),
        const SizedBox(width: 8),
        Text(_fmt(seconds),
            style: TextStyle(
                fontFamily: DuoFonts.display, fontSize: 22,
                color: warning ? DuoColors.cardinal : DuoColors.eel2,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

/// 하단 흰 pill HUD — 좌(깃발+값) · 가운데 부유 레이더 · 우(핀+값).
class RadarPillHUD extends StatelessWidget {
  final String leftLabel, leftValue, rightLabel, rightValue;
  final Widget radar;
  const RadarPillHUD({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.radar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Expanded(child: _side(DuoColors.macawBg, DuoColors.macaw, Icons.flag, leftLabel, leftValue, DuoColors.fox, true)),
          const SizedBox(width: 72),
          Expanded(child: _side(DuoColors.green500, Colors.white, Icons.place, rightLabel, rightValue, DuoColors.green500, false)),
        ]),
      ),
      Positioned(top: -8, child: SizedBox(width: 76, height: 76, child: radar)),
    ]);
  }

  Widget _side(Color box, Color icon, IconData ic, String label, String value, Color valueColor, bool left) {
    final texts = Column(
      crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, color: DuoColors.hare)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: valueColor)),
      ],
    );
    final badge = Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: box, borderRadius: BorderRadius.circular(9)),
      child: Icon(ic, size: 18, color: icon),
    );
    return Padding(
      padding: EdgeInsets.only(left: left ? 14 : 0, right: left ? 0 : 14),
      child: Row(
        mainAxisAlignment: left ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: left ? [badge, const SizedBox(width: 10), Expanded(child: texts)]
                       : [Expanded(child: texts), const SizedBox(width: 10), badge],
      ),
    );
  }
}

/// 간단한 레이더 디스크 (녹색 그라데이션 + 십자선). AR 라디어 디스크 축약.
class RadarDisc extends StatelessWidget {
  const RadarDisc({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [DuoColors.green300, DuoColors.green900]),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: const Center(child: Icon(Icons.my_location, color: Colors.white70, size: 22)),
    );
  }
}

/// 베어링 바늘 레이더 — AR 하단 HUD 중앙 (ARRadarView.swift 이식, north-up).
/// 그라데이션 디스크 + 흰/다크 보더 + 동심원 2개 + 십자선 +
/// 폰 방향 흰색 부채꼴(50°, 헤딩으로 회전, RadarSectorWedge) +
/// 아이템 방향 노란 바늘(절대 베어링으로 회전, assets/radar/radar_item.png) +
/// 노란 중앙 허브.
class BearingRadarDisc extends StatelessWidget {
  final double headingDegrees;
  final double? itemBearingDegrees;
  const BearingRadarDisc({super.key, this.headingDegrees = 0, this.itemBearingDegrees});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final size = c.biggest.shortestSide;
      return Stack(alignment: Alignment.center, children: [
        // 디스크 + 보더 + 동심원 + 십자선 + 폰 부채꼴 + 중앙 허브 (Custom painter).
        SizedBox(width: size, height: size, child: CustomPaint(painter: _RadarDiscPainter(headingDegrees: headingDegrees))),
        // 아이템 바늘 — SwiftUI 와 동일하게 PNG 자산을 회전 (anchor 가 디스크 중심).
        if (itemBearingDegrees != null)
          Transform.rotate(
            angle: itemBearingDegrees! * math.pi / 180.0,
            child: SizedBox(
              width: size, height: size,
              // bottom 정렬 + 위쪽 절반에만 그림 → bottom anchor 회전 효과.
              child: Padding(
                padding: EdgeInsets.only(bottom: size / 2),
                child: Center(
                  child: SizedBox(
                    height: size * 0.45,
                    child: Image.asset(
                      'assets/radar/radar_item.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => CustomPaint(painter: _NeedleFallback()),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

/// PNG 자산 누락 폴백 — 노란 다이아몬드 바늘(11:25 비율).
class _NeedleFallback extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.55)
      ..lineTo(w / 2, h)
      ..lineTo(0, h * 0.55)
      ..close();
    canvas.drawPath(p, Paint()..color = DuoColors.bee);
  }

  @override
  bool shouldRepaint(covariant _) => false;
}

class _RadarDiscPainter extends CustomPainter {
  final double headingDegrees;
  _RadarDiscPainter({required this.headingDegrees});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // 그라데이션 디스크 + 흰 outer 보더 + 안쪽 dark 보더.
    final disc = Paint()
      ..shader = const RadialGradient(colors: [DuoColors.green300, DuoColors.green900])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, disc);
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    canvas.drawCircle(c, r - 2, Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // 동심원 2개 (디스크 크기 18%/32% inset) — 흰색 35%/30%.
    final d = r * 2;
    canvas.drawCircle(c, r - d * 0.18, Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    canvas.drawCircle(c, r - d * 0.32, Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // 십자선 (40% 흰색).
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), cross);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), cross);

    // 폰 방향 흰 부채꼴 (50°, radiusRatio 0.86) — 헤딩으로 회전.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(headingDegrees * math.pi / 180.0);
    final wedge = _wedgePath(r * 0.86, 50);
    canvas.drawPath(wedge, Paint()..color = Colors.white.withValues(alpha: 0.65));
    canvas.drawPath(wedge, Paint()
      ..color = DuoColors.eel2.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    canvas.restore();

    // 아이템 방향 노란 바늘은 BearingRadarDisc 위젯이 Stack 으로 Image.asset(radar_item)
    // 을 회전하여 그린다 (SwiftUI 와 동일 — PNG 자산 그대로 사용).

    // 중앙 허브 — bee yellow 7px + dark stroke 1.2 + glow.
    canvas.drawCircle(c, 3.5, Paint()
      ..color = DuoColors.bee.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(c, 3.5, Paint()..color = DuoColors.bee);
    canvas.drawCircle(c, 3.5, Paint()
      ..color = DuoColors.eel2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
  }

  /// 위(12시)로 향한 부채꼴(파이 섹터). 반경 [r], 꼭지각 [angleDeg].
  Path _wedgePath(double r, double angleDeg) {
    final p = Path();
    final half = angleDeg / 2 * math.pi / 180.0;
    final start = -math.pi / 2 - half;
    final sweep = 2 * half;
    p.moveTo(0, 0);
    p.arcTo(Rect.fromCircle(center: Offset.zero, radius: r), start, sweep, false);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _RadarDiscPainter old) => old.headingDegrees != headingDegrees;
}

/// 맵 하단 HUD — SwiftUI LegacyBottomBar 이식.
/// 4 stat chip(지뢰/필수/HIDDEN/STEALTH) + 가운데 부유 카메라 버튼(76, offset -8).
class MapBottomBar extends StatelessWidget {
  final int mineCount, mandatoryRemaining, hiddenCount, stealthCount;
  final VoidCallback onCamera;
  const MapBottomBar({
    super.key,
    required this.mineCount,
    required this.mandatoryRemaining,
    required this.hiddenCount,
    required this.stealthCount,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Expanded(child: _StatChip(label: '지뢰', value: mineCount, valueColor: DuoColors.macaw)),
          Expanded(child: _StatChip(label: '필수', value: mandatoryRemaining, valueColor: DuoColors.fox)),
          const SizedBox(width: 72), // 카메라 자리
          Expanded(child: _StatChip(label: 'HIDDEN', value: hiddenCount, valueColor: DuoColors.wolf2)),
          Expanded(child: _StatChip(label: 'STEALTH', value: stealthCount, valueColor: DuoColors.beetleDeep)),
          const SizedBox(width: 12),
        ]),
      ),
      Positioned(
        top: -8,
        child: GestureDetector(
          onTap: onCamera,
          child: Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DuoColors.green500,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ),
      ),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color valueColor;
  const _StatChip({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(
            fontFamily: DuoFonts.display, fontSize: 10, color: DuoColors.hare, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text('$value', style: TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: valueColor)),
      ],
    );
  }
}
