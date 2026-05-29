// features/play/popups.dart — ItemAcquiredPopup V2(쇼케이스) + 미션 결과 팝업 (디자인 이식).
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../design_system/candy_button.dart';
import '../../design_system/duo_tokens.dart';
import '../../game/play_alert.dart';

/// 아이템 획득 팝업 — 쇼케이스 헤더(회전 광선 + 펄스 링) + 본문 + 캔디 OK.
class ItemAcquiredPopup extends StatefulWidget {
  final ItemAcquiredAlert alert;
  final VoidCallback onOK;
  const ItemAcquiredPopup({super.key, required this.alert, required this.onOK});

  @override
  State<ItemAcquiredPopup> createState() => _ItemAcquiredPopupState();
}

class _ItemAcquiredPopupState extends State<ItemAcquiredPopup> with TickerProviderStateMixin {
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void dispose() {
    _glow.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    return Center(
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DuoColors.swan2, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 쇼케이스 헤더
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(alignment: Alignment.center, children: [
                Container(color: DuoColors.eel2),
                AnimatedBuilder(
                  animation: _glow,
                  builder: (_, _) => Transform.rotate(
                    angle: _glow.value * 2 * math.pi,
                    child: Container(
                      width: 150, height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: [
                          Colors.transparent, DuoColors.bee, Colors.transparent,
                          Colors.transparent, DuoColors.green400, Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: DuoColors.green500, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: DuoColors.bee.withValues(alpha: 0.6), blurRadius: 18)],
                  ),
                  child: const Icon(Icons.card_giftcard, color: Colors.white, size: 30),
                ),
                const Positioned(
                  bottom: 10,
                  child: Text('ITEM ACQUIRED · 아이템 획득',
                      style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, color: DuoColors.bee, letterSpacing: 0.5)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                Text(widget.alert.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 20, color: DuoColors.eel2)),
                const SizedBox(height: 8),
                Text(widget.alert.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: DuoColors.wolf2)),
                const SizedBox(height: 16),
                CandyButton(label: 'OK · 확인', tint: DuoColors.fox, shadowColor: DuoColors.foxDeep, onPressed: widget.onOK),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 미션 결과 팝업 (완료/시간초과).
class MissionResultPopup extends StatelessWidget {
  final bool success;
  final String elapsedText;
  final VoidCallback onClose;
  const MissionResultPopup({super.key, required this.success, required this.elapsedText, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(success ? Icons.emoji_events : Icons.timer_off,
              size: 56, color: success ? DuoColors.bee : DuoColors.hare),
          const SizedBox(height: 12),
          Text(success ? '미션 완료!' : '시간 초과',
              style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.eel2)),
          const SizedBox(height: 6),
          Text(success ? '소요 시간 $elapsedText' : '제한 시간이 지났습니다.',
              style: const TextStyle(fontSize: 14, color: DuoColors.hare)),
          const SizedBox(height: 18),
          CandyButton(label: '나가기', onPressed: onClose),
        ]),
      ),
    );
  }
}
