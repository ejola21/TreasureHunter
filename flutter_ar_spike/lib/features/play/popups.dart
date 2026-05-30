// features/play/popups.dart — ItemAcquiredPopup V2(쇼케이스) + 미션 결과 팝업 (디자인 이식).
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
  void initState() {
    super.initState();
    // SwiftUI ItemAcquiredPopup onAppear: HapticService.shared.success()
    WidgetsBinding.instance.addPostFrameCallback((_) => HapticFeedback.heavyImpact());
  }

  void _confirm() {
    HapticFeedback.heavyImpact(); // SwiftUI OK 버튼: vibrate(.heavy)
    widget.onOK();
  }

  @override
  void dispose() {
    _glow.dispose();
    _pop.dispose();
    super.dispose();
  }

  Widget _fallbackIcon() => Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: DuoColors.green500, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: DuoColors.bee.withValues(alpha: 0.6), blurRadius: 18)],
        ),
        child: const Icon(Icons.card_giftcard, color: Colors.white, size: 30),
      );

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
                widget.alert.itemIconName.isNotEmpty
                    ? Image.asset(widget.alert.itemIconName, width: 72, height: 72,
                        errorBuilder: (_, _, _) => _fallbackIcon())
                    : _fallbackIcon(),
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
                CandyButton(label: 'OK · 확인', tint: DuoColors.fox, shadowColor: DuoColors.foxDeep, onPressed: _confirm),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// SwiftUI MissionCompletePopup.swift 이식 — 별점 + 후기 입력 + 건너뛰기/제출.
/// 트로피 아이콘(bee) + "Mission Cleared" kicker + 별점 + 후기 입력.
class MissionCompletePopup extends StatefulWidget {
  final void Function(int score, String reply) onSubmit;
  final VoidCallback onSkip;
  const MissionCompletePopup({super.key, required this.onSubmit, required this.onSkip});

  @override
  State<MissionCompletePopup> createState() => _MissionCompletePopupState();
}

class _MissionCompletePopupState extends State<MissionCompletePopup> {
  int _rating = 0;
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Material 래퍼 — TextField 가 ink/Material ancestor 를 요구하므로 필수.
    // 키보드 올라올 때 팝업이 가려지지 않도록 viewInsets.bottom 으로 위로 이동 + 스크롤 가능.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
          // 트로피 — 80×80 beeBg + 40pt bee 트로피 + glow.
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: DuoColors.beeBg, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: DuoColors.bee.withValues(alpha: 0.4), blurRadius: 12)],
            ),
            child: const Icon(Icons.emoji_events, size: 40, color: DuoColors.bee),
          ),
          const SizedBox(height: 14),
          const Text('MISSION CLEARED',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 12, color: DuoColors.bee, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          const Text('미션 완료!',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 26, color: DuoColors.eel2)),
          const SizedBox(height: 14),
          const Text('이 미션은 어땠나요?',
              style: TextStyle(fontSize: 14, color: DuoColors.wolf2)),
          const SizedBox(height: 10),
          // 별점 5개.
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
            final on = i < _rating;
            return IconButton(
              onPressed: () => setState(() => _rating = i + 1),
              icon: Icon(on ? Icons.star : Icons.star_border, color: on ? DuoColors.bee : DuoColors.hare, size: 32),
              padding: const EdgeInsets.symmetric(horizontal: 2),
            );
          })),
          const SizedBox(height: 8),
          // 후기 입력 (선택).
          Container(
            decoration: BoxDecoration(color: DuoColors.snow, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DuoColors.swan2, width: 1.5)),
            child: TextField(
              controller: _reply,
              minLines: 2, maxLines: 3, maxLength: 100,
              decoration: const InputDecoration(
                hintText: '간단한 한 줄 후기를 적어주세요 (선택)',
                hintStyle: TextStyle(fontSize: 12, color: DuoColors.hare),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: InputBorder.none, counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: CandyButton(label: '건너뛰기', tint: DuoColors.swan, shadowColor: DuoColors.hare, onPressed: widget.onSkip),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CandyButton(label: '제출', tint: DuoColors.bee, shadowColor: DuoColors.beeDeep,
                  onPressed: () => widget.onSubmit(_rating, _reply.text.trim())),
            ),
          ]),
        ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 미션 결과 팝업 (시간초과 전용 — 완료는 MissionCompletePopup 사용).
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
