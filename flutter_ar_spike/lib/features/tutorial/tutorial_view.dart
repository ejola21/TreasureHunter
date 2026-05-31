// features/tutorial/tutorial_view.dart — SwiftUI TutorialView.swift 이식 (185줄).
// 3-step 인터랙티브 온보딩: SKIP + 3-dot progress + X / 타이틀 / 데모 카드 / 말풍선 / BACK·NEXT.
// FoxMascot/ItemPin 일러스트는 Flutter 미이식 → 단순 아이콘 + emoji 로 대체.
import 'package:flutter/material.dart';
import '../../design_system/candy_button.dart';
import '../../design_system/duo_tokens.dart';

class _TutorialStep {
  final String kicker, title, body, mascotEmoji;
  final IconData pinIcon;
  final Color pinColor;
  final IconData handIcon;
  const _TutorialStep({
    required this.kicker,
    required this.title,
    required this.body,
    required this.pinIcon,
    required this.pinColor,
    required this.handIcon,
    required this.mascotEmoji,
  });
}

class TutorialView extends StatefulWidget {
  const TutorialView({super.key});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  int _step = 0;

  static const _steps = [
    _TutorialStep(
      kicker: 'STEP 1',
      title: '지도에서 아이템 찾기',
      body: '근처에 숨겨진 아이템 핀이 지도에 표시돼요. 가까이 다가가면 활성화!',
      pinIcon: Icons.flag, pinColor: DuoColors.macaw,
      handIcon: Icons.touch_app, mascotEmoji: '👋',
    ),
    _TutorialStep(
      kicker: 'STEP 2',
      title: 'AR로 흔들고 터치하기',
      body: '거리 안에 들어가면 카메라를 켜고 화면을 흔들거나 탭해서 아이템을 획득해요.',
      pinIcon: Icons.help_outline, pinColor: DuoColors.bee,
      handIcon: Icons.back_hand, mascotEmoji: '🤔',
    ),
    _TutorialStep(
      kicker: 'STEP 3',
      title: '퀴즈 풀고 클리어!',
      body: '필수 아이템을 모두 획득하면 미션 완료! 보상과 뱃지를 받아보세요.',
      pinIcon: Icons.emoji_events, pinColor: DuoColors.green500,
      handIcon: Icons.celebration, mascotEmoji: '🎉',
    ),
  ];

  _TutorialStep get _current => _steps[_step];
  bool get _isLast => _step == _steps.length - 1;
  bool get _isFirst => _step == 0;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.snow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(children: [
            _topBar(),
            const Spacer(flex: 1),
            _titleSection(),
            const Spacer(flex: 1),
            _demoCard(),
            const Spacer(flex: 1),
            _mascotBubble(),
            const Spacer(flex: 1),
            _navButtons(),
          ]),
        ),
      ),
    );
  }

  Widget _topBar() {
    // SKIP 제거 — X 한 개로 통일. 좌측에 X 와 동일 폭 spacer 두어 3-dot 가운데 정렬 유지.
    const closeBoxSize = 44.0;
    return Row(children: [
      const SizedBox(width: closeBoxSize),
      // 3-dot progress (가운데 정렬)
      Expanded(
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(_steps.length, (i) {
            final on = i == _step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 22 : 8, height: 6,
              decoration: BoxDecoration(
                color: on ? DuoColors.macaw : DuoColors.swan,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          })),
        ),
      ),
      // X 닫기 — 44×44 흰 둥근 박스 + 어두운 X 아이콘 (탭 영역 확장 + 시인성 강화).
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Container(
          width: closeBoxSize, height: closeBoxSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white, shape: BoxShape.circle,
            border: Border.all(color: DuoColors.swan2, width: 2),
          ),
          child: const Icon(Icons.close, size: 22, weight: 900, color: DuoColors.eel2),
        ),
      ),
    ]);
  }

  Widget _titleSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_current.kicker,
            style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.foxDeep)),
        const SizedBox(height: 6),
        Text(_current.title,
            style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 24, color: DuoColors.eel2)),
      ]),
    );
  }

  Widget _demoCard() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EED4), // SwiftUI hex 0xE7EED4
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(children: [
        // 핀 + 펄스 링 — 중앙
        Center(child: _PulsePin(icon: _current.pinIcon, color: _current.pinColor)),
        // 손가락 — 우상단 약간 안쪽
        Positioned(
          right: 40, top: 30,
          child: Transform.rotate(
            angle: _step == 1 ? 0 : -25 * 3.14159 / 180,
            child: Icon(_current.handIcon, size: 36, color: DuoColors.foxDeep, weight: 900),
          ),
        ),
      ]),
    );
  }

  Widget _mascotBubble() {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // Fox mascot 대체 — emoji
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: DuoColors.foxBg, shape: BoxShape.circle,
          border: Border.all(color: DuoColors.foxDeep, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(_current.mascotEmoji, style: const TextStyle(fontSize: 28)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DuoColors.swan2, width: 2),
          ),
          child: Text(_current.body,
              style: const TextStyle(fontSize: 13, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  Widget _navButtons() {
    return Row(children: [
      if (!_isFirst) ...[
        Expanded(
          child: CandyButton(
            label: 'BACK', tint: Colors.white, shadowColor: DuoColors.swan2,
            fg: DuoColors.wolf, // 흰 배경에서 보이게 어두운 회색 (SwiftUI duoWolf 동일).
            onPressed: () => setState(() => _step -= 1),
          ),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: _isLast
            ? CandyButton(
                label: "LET'S PLAY!",
                tint: DuoColors.green500, shadowColor: DuoColors.green700,
                onPressed: _close,
              )
            : CandyButton(
                label: 'NEXT',
                tint: DuoColors.macaw, shadowColor: DuoColors.macawDeep,
                onPressed: () => setState(() => _step += 1),
              ),
      ),
    ]);
  }
}

/// 펄스 링 + 아이콘 핀 — SwiftUI ItemPin + PulseRing 단순 대체.
class _PulsePin extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsePin({required this.icon, required this.color});

  @override
  State<_PulsePin> createState() => _PulsePinState();
}

class _PulsePinState extends State<_PulsePin> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, height: 120,
      child: Stack(alignment: Alignment.center, children: [
        // 펄스 링
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Container(
            width: 56 + _c.value * 56,
            height: 56 + _c.value * 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DuoColors.bee.withValues(alpha: (1 - _c.value) * 0.7), width: 3),
            ),
          ),
        ),
        // 본체 핀
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: widget.color, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 12)],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 28),
        ),
      ]),
    );
  }
}
