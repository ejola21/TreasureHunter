// design_system/play_hud.dart — 플레이 HUD (WhitePillTimer + RadarPillHUD) 디자인 이식.
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
