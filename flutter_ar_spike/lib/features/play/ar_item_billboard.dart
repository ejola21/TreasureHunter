// features/play/ar_item_billboard.dart — SwiftUI ARItemView.swift 6-애니메이션 이식.
// (a) float ±12pt (spring 2.2s autoreverse forever)
// (b) sway ±5°  (easeInOut 2.8s autoreverse forever)
// (c) pop 1.0→1.08 (easeInOut 2.2s autoreverse forever)
// (d) pulse rings 2개 — 0.7→2.0 스케일, 70pt, opacity 1→0, stagger duration/2 (1.6s, duoBee × 0.7)
// (e) conic glow — AngularGradient duoBee 0.55, 14pt stroke 140×140, 3.6s linear, blur 2
// (f) sparkles 3개 — (-22,4)/(0,-8)/(22,6) 위치, 1.4s, rise 60pt, stagger duration/3, 8각 별, duoBee
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/mission_item.dart';

class ARItemBillboard extends StatefulWidget {
  final MissionItem item;
  final bool isAcquired;
  final bool isHiddenByShowType; // Stealth + 레이더 없음 → placeholder 만
  final VoidCallback? onTap;
  const ARItemBillboard({
    super.key,
    required this.item,
    this.isAcquired = false,
    this.isHiddenByShowType = false,
    this.onTap,
  });

  @override
  State<ARItemBillboard> createState() => _ARItemBillboardState();
}

class _ARItemBillboardState extends State<ARItemBillboard> with TickerProviderStateMixin {
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  late final AnimationController _sway =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
  late final AnimationController _spark =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    for (final c in [_float, _sway, _pop, _ring, _glow, _spark]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHiddenByShowType) return const _StealthPlaceholder();
    final acquired = widget.isAcquired;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 200, height: 200,
        child: Stack(alignment: Alignment.center, children: [
          if (!acquired) _PulseRings(c: _ring),
          if (!acquired) _ConicGlow(c: _glow),
          // 본체 — float + sway + pop 결합.
          AnimatedBuilder(
            animation: Listenable.merge([_float, _sway, _pop]),
            builder: (_, _) {
              final dy = (acquired ? 0.0 : (math.sin(_float.value * math.pi) * 2 - 1) * 12);
              final ang = (acquired ? 0.0 : (math.sin(_sway.value * math.pi) * 2 - 1) * 5 * math.pi / 180);
              final scl = acquired ? 1.0 : (1.0 + (math.sin(_pop.value * math.pi) * 2 - 1).abs() * 0.04 - 0.04 + 0.04);
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(
                  angle: ang,
                  child: Transform.scale(scale: scl, child: _icon(acquired)),
                ),
              );
            },
          ),
          if (!acquired) _Sparkles(c: _spark),
        ]),
      ),
    );
  }

  Widget _icon(bool acquired) {
    Widget child = Image.asset(widget.item.arIconName, width: 90, height: 108, fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback());
    if (acquired) {
      child = Opacity(opacity: 0.4, child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: child,
      ));
    }
    // 필수 별 배지.
    return SizedBox(
      width: 110, height: 120,
      child: Stack(clipBehavior: Clip.none, children: [
        Center(child: child),
        if (widget.item.isMandatory && !acquired)
          Positioned(
            right: 0, top: 6,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: DuoColors.bee, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.star, size: 13, color: Colors.white, weight: 900),
            ),
          ),
      ]),
    );
  }

  Widget _fallback() => Container(
        width: 90, height: 108,
        decoration: BoxDecoration(
          color: widget.item.isMandatory ? DuoColors.fox : DuoColors.green500,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(widget.item.itemType.displayLabel.characters.first,
            style: const TextStyle(color: Colors.white, fontFamily: DuoFonts.display, fontSize: 28)),
      );
}

// (d) 펄스 링 — 2 stagger, 0.7→2.0, opacity 1→0, duoBee × 0.7
class _PulseRings extends StatelessWidget {
  final AnimationController c;
  const _PulseRings({required this.c});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => CustomPaint(painter: _PulseRingsPainter(t: c.value), size: const Size(200, 200)),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  final double t;
  _PulseRingsPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 2; i++) {
      final phase = (t + i * 0.5) % 1.0;
      final scale = 0.7 + (2.0 - 0.7) * phase;
      final r = 35 * scale; // base 70/2
      final alpha = (1 - phase) * 0.7;
      canvas.drawCircle(c, r, Paint()
        ..color = DuoColors.bee.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingsPainter old) => old.t != t;
}

// (e) Conic glow — 회전하는 angular gradient stroke
class _ConicGlow extends StatelessWidget {
  final AnimationController c;
  const _ConicGlow({required this.c});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => Transform.rotate(
        angle: c.value * 2 * math.pi,
        child: CustomPaint(painter: _GlowPainter(), size: const Size(140, 140)),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          DuoColors.bee.withValues(alpha: 0.55),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.0, 0.18, 0.40, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant _) => false;
}

// (f) Sparkles — 3 stars at offsets, rise + fade
class _Sparkles extends StatelessWidget {
  final AnimationController c;
  const _Sparkles({required this.c});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => CustomPaint(painter: _SparklePainter(t: c.value), size: const Size(200, 200)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double t;
  _SparklePainter({required this.t});
  static const _offsets = [Offset(-22, 4), Offset(0, -8), Offset(22, 6)];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < _offsets.length; i++) {
      final phase = (t + i / 3.0) % 1.0;
      final rise = phase * 60.0;
      final scale = 0.6 + 0.6 * (1 - phase);
      final alpha = (1 - phase) * (phase < 0.1 ? phase * 10 : 1.0);
      final pos = c + _offsets[i] + Offset(0, -rise);
      _drawStar(canvas, pos, 4.0 * scale, DuoColors.bee.withValues(alpha: alpha));
    }
  }

  void _drawStar(Canvas canvas, Offset pos, double r, Color color) {
    final p = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * 0.4;
      final a = -math.pi / 2 + i * math.pi / points;
      final pt = pos + Offset(math.cos(a) * radius, math.sin(a) * radius);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}

class _StealthPlaceholder extends StatelessWidget {
  const _StealthPlaceholder();
  @override
  Widget build(BuildContext context) {
    // 스텔스 + 레이더 없음 — 아이콘은 그리지 않고 hint 만(부모 stealthHUD 가 안내).
    return const SizedBox(width: 200, height: 200);
  }
}
