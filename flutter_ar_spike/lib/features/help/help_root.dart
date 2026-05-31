// features/help/help_root.dart — SwiftUI Help/* 4 파일 1:1 이식.
// HelpRoot (라우터, 3 탭) + HelpItemsView + HelpHowToView + HelpDesignView.
// SwiftUI SegmentedTabs (green theme) / SwiftUI HelpRoot.header / 각 view 의 hero+groups 그대로.
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/item_type.dart';
import '../../models/item_type_detail.dart';

enum HelpTab { items, howto, design }

class HelpRoot extends StatefulWidget {
  final HelpTab initial;
  final VoidCallback? onStartDesign;
  const HelpRoot({super.key, this.initial = HelpTab.items, this.onStartDesign});

  @override
  State<HelpRoot> createState() => _HelpRootState();
}

class _HelpRootState extends State<HelpRoot> {
  late HelpTab _tab = widget.initial;

  String _label(HelpTab t) => switch (t) {
        HelpTab.items => 'Items',
        HelpTab.howto => 'How to Play',
        HelpTab.design => 'Design',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.snow,
      body: SafeArea(
        child: Column(children: [
          _header(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _segmentedTabs(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_tab) {
                HelpTab.items => const _HelpItemsView(),
                HelpTab.howto => const _HelpHowToView(),
                HelpTab.design => _HelpDesignView(onStartDesign: widget.onStartDesign),
              },
            ),
          ),
        ]),
      ),
    );
  }

  /// SwiftUI HelpRoot.header — 동그란 흰 ← 버튼 + kicker "Help · 도움말" + 큰 제목.
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: DuoColors.swan2, width: 2),
            ),
            child: const Icon(Icons.chevron_left, size: 18, color: DuoColors.eel2, weight: 900),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('HELP · 도움말',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
          Text(_label(_tab),
              style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.eel2)),
        ]),
      ]),
    );
  }

  /// SwiftUI SegmentedTabs (theme=green500/bg=green100/deep=green800).
  /// 활성: green100 fill + green500 2pt border + green800 텍스트. 비활성: 흰 fill + swan2 border + hare 텍스트.
  /// 텍스트 UPPERCASE + kerning 0.6 + height 44.
  Widget _segmentedTabs() {
    return Row(children: HelpTab.values.map((t) {
      final active = t == _tab;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => _tab = t),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? DuoColors.green100 : Colors.white,
                borderRadius: BorderRadius.circular(DuoRadius.lg),
                border: Border.all(
                  color: active ? DuoColors.green500 : DuoColors.swan2, width: 2),
              ),
              child: Text(_label(t).toUpperCase(),
                  style: TextStyle(
                    fontFamily: DuoFonts.display,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: active ? DuoColors.green800 : DuoColors.hare,
                  )),
            ),
          ),
        ),
      );
    }).toList());
  }
}

// ─── §14 Item Glossary ───────────────────────────────────────────────────────
// SwiftUI HelpItemsView 1:1 — Property legend + 5 그룹 카드 (Mission/Quiz/Radar/Time/Special).
class _HelpItemsView extends StatelessWidget {
  const _HelpItemsView();

  static const _groups = [
    (
      title: 'Mission · 핵심', sub: '미션 진행에 필요한 아이템',
      tint: DuoColors.green800, bg: DuoColors.green100,
      types: [ItemType.start, ItemType.end, ItemType.simple, ItemType.mine, ItemType.mineNoBomb, ItemType.random],
    ),
    (
      title: 'Quiz · 퀴즈', sub: '정답을 맞춰야 획득',
      tint: DuoColors.cardinalDeep, bg: DuoColors.cardinalBg,
      types: [ItemType.quiz, ItemType.solution],
    ),
    (
      title: 'Radar · 레이더', sub: '숨김 아이템을 보이게',
      tint: DuoColors.beetleDeep, bg: Color(0xFFF1DCFF),
      types: [ItemType.radarMap, ItemType.radarMine, ItemType.radarAR, ItemType.radarAll],
    ),
    (
      title: 'Time · 시간', sub: '타임어택 트리거',
      tint: DuoColors.macawDeep, bg: DuoColors.macawBg,
      types: [ItemType.timeoutStart, ItemType.timeoutEnd],
    ),
    (
      title: 'Special · 특수', sub: '특수 효과 아이템',
      tint: DuoColors.foxDeep, bg: DuoColors.foxBg,
      types: [ItemType.black, ItemType.store, ItemType.coupon],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _propertyLegend(),
        const SizedBox(height: 16),
        for (final g in _groups) ...[
          _groupCard(g),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  Widget _propertyLegend() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PROPERTIES · 아이템 속성',
          style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DuoColors.swan2, width: 2),
        ),
        child: Column(children: const [
          _LegendRow(emoji: '👁️', label: 'Visible', desc: '지도와 AR 화면에서 모두 표시'),
          _RowDivider(),
          _LegendRow(emoji: '🗺️', label: 'Hidden', desc: '지도에서 숨김 (AR 에서만 보임)'),
          _RowDivider(),
          _LegendRow(emoji: '🥷', label: 'Stealth', desc: '지도에는 표시, AR 거리·방향 정보 숨김'),
          _RowDivider(),
          _LegendRow(emoji: '⭐', label: '필수', desc: '획득해야 미션 클리어'),
        ]),
      ),
    ]);
  }

  Widget _groupCard(({String title, String sub, Color tint, Color bg, List<ItemType> types}) g) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: g.tint, width: 2), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          // 헤더 (컬러 bg + 흰 텍스트)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: g.tint,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: Colors.white)),
              Text(g.sub, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            ]),
          ),
          // 아이템 row
          ColoredBox(
            color: Colors.white,
            child: Column(children: [
              for (var i = 0; i < g.types.length; i++) ...[
                _ItemRow(type: g.types[i]),
                if (i < g.types.length - 1) const _RowDivider(),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String emoji, label, desc;
  const _LegendRow({required this.emoji, required this.label, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 13, color: DuoColors.eel2)),
        ),
        Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: DuoColors.wolf2, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: const EdgeInsets.only(left: 14), color: DuoColors.swan);
}

class _ItemRow extends StatelessWidget {
  final ItemType type;
  const _ItemRow({required this.type});

  @override
  Widget build(BuildContext context) {
    // SwiftUI 와 동일하게 type.detailGuide.effect 사용 (item_type_detail.dart 의 정식 텍스트).
    final effect = type.detailGuide.effect;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Image.asset(
          type.mapIcon(mandatory: false),
          width: 42, height: 42,
          errorBuilder: (_, _, _) => Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: DuoColors.swan2, shape: BoxShape.circle),
            child: const Icon(Icons.help_outline, color: DuoColors.eel2, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(type.displayLabel,
              style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
          const SizedBox(height: 4),
          Text(effect, style: const TextStyle(fontSize: 11, color: DuoColors.wolf2)),
        ])),
      ]),
    );
  }
}

// ─── §15 How To Play ─────────────────────────────────────────────────────────
// SwiftUI HelpHowToView 1:1 — orange hero(PlaySpot?) + 2 modes + 4 steps + reward strip + fox bubble.
class _HelpHowToView extends StatelessWidget {
  const _HelpHowToView();

  static const _steps = [
    (id: 1, title: '지도 열고 미션 찾기', body: '근처에 숨겨진 아이템을 지도에서 확인하세요.',
        icon: Icons.map, tint: DuoColors.macaw),
    (id: 2, title: '직접 걸어서 이동', body: '표시된 위치까지 직접 걸어가야 아이템이 활성화됩니다.',
        icon: Icons.directions_walk, tint: DuoColors.fox),
    (id: 3, title: 'AR로 흔들고 터치!', body: '거리 안에 들어가면 카메라를 켜고 흔들거나 터치해 획득.',
        icon: Icons.auto_awesome, tint: DuoColors.beetle),
    (id: 4, title: '퀴즈 풀고 클리어', body: '퀴즈 정답을 맞춰 모든 필수 아이템을 모으면 클리어!',
        icon: Icons.emoji_events, tint: DuoColors.bee),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heroCard(),
        const SizedBox(height: 16),
        _modeCards(),
        const SizedBox(height: 16),
        _stepsList(),
        const SizedBox(height: 16),
        _rewardStrip(),
        const SizedBox(height: 16),
        _foxBubble(),
      ]),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [DuoColors.foxBg, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.fox.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('WHAT IS · 플레이스팟이란?',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.foxDeep)),
          SizedBox(height: 6),
          Text('PlaySpot?',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 26, color: DuoColors.eel2)),
          SizedBox(height: 4),
          Text('실제 위치를 돌아다니며 AR로 아이템을 모으는\n위치 기반 트레저 헌트 게임이에요.',
              style: TextStyle(fontSize: 13, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        const Text('🦊', style: TextStyle(fontSize: 56)),
      ]),
    );
  }

  Widget _modeCards() {
    return Row(children: [
      Expanded(child: _modeCard(kicker: 'LIVE', title: '리얼 모드', desc: '실제 GPS로 직접 걸으면서 플레이',
          tint: DuoColors.green500, bg: DuoColors.green100)),
      const SizedBox(width: 10),
      Expanded(child: _modeCard(kicker: 'HOME', title: '가상 모드', desc: '집에서도 위치를 시뮬레이션해 즐기기',
          tint: DuoColors.beetle, bg: const Color(0xFFF1DCFF))),
    ]);
  }

  Widget _modeCard({required String kicker, required String title, required String desc, required Color tint, required Color bg}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: tint, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 22, alignment: Alignment.center,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(999)),
          child: Text(kicker, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 10, color: Colors.white, letterSpacing: 0.66)),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
        const SizedBox(height: 4),
        Text(desc, maxLines: 3, style: const TextStyle(fontSize: 11, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _stepsList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('HOW TO PLAY · 4 STEPS',
          style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
      const SizedBox(height: 10),
      for (final s in _steps) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: DuoColors.swan2, width: 2)),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: s.tint, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${s.id}', style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
              const SizedBox(height: 2),
              Text(s.body, style: const TextStyle(fontSize: 12, color: DuoColors.wolf2)),
            ])),
            Icon(s.icon, color: s.tint, size: 24, weight: 900),
          ]),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }

  Widget _rewardStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DuoColors.eel2, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REWARDS · 보상',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 10),
        Row(children: const [
          Expanded(child: _PerkChip(icon: Icons.bolt, label: 'XP', tint: DuoColors.bee)),
          Expanded(child: _PerkChip(icon: Icons.diamond, label: 'GEM', tint: DuoColors.beetle)),
          Expanded(child: _PerkChip(icon: Icons.local_fire_department, label: 'STREAK', tint: DuoColors.fox)),
          Expanded(child: _PerkChip(icon: Icons.workspace_premium, label: 'BADGE', tint: DuoColors.macaw)),
        ]),
      ]),
    );
  }

  Widget _foxBubble() {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: DuoColors.foxBg, shape: BoxShape.circle, border: Border.all(color: DuoColors.foxDeep, width: 2)),
        alignment: Alignment.center,
        child: const Text('🦊', style: TextStyle(fontSize: 32)),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: DuoColors.swan2, width: 2)),
        child: const Text('준비됐어요? 🎯',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
      ),
    ]);
  }
}

class _PerkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  const _PerkChip({required this.icon, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: tint.withValues(alpha: 0.25), shape: BoxShape.circle),
        child: Icon(icon, color: tint, size: 16, weight: 900),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontFamily: DuoFonts.display, fontSize: 10, letterSpacing: 0.6, color: Colors.white.withValues(alpha: 0.85))),
    ]);
  }
}

// ─── §16 Design (미션 디자이너) ─────────────────────────────────────────────
// SwiftUI HelpDesignView 1:1 — purple hero (Mission Designer) + 5 DesignStep (64x64 tint icon box) + CTA.
class _HelpDesignView extends StatelessWidget {
  final VoidCallback? onStartDesign;
  const _HelpDesignView({this.onStartDesign});

  static const _steps = [
    (id: 1, title: '지도에 아이템 배치', body: '지도를 길게 눌러 시작/끝/퀴즈/지뢰 등 아이템을 놓아보세요.',
        icon: Icons.map, tint: DuoColors.green500),
    (id: 2, title: '아이템 탭해서 설정', body: '필수 여부·발견 거리·표시 방식(숨김/Stealth) 등을 조정.',
        icon: Icons.tune, tint: DuoColors.macaw),
    (id: 3, title: '미션 메타 정보 입력', body: '제목·장소·설명·시간 제한·뱃지 이미지를 채워주세요.',
        icon: Icons.article, tint: DuoColors.fox),
    (id: 4, title: '테스트 플레이', body: "내 디자인 목록에서 '테스트' 버튼으로 직접 플레이해보세요.",
        icon: Icons.play_arrow, tint: DuoColors.beetle),
    (id: 5, title: '업로드 — 신중하게!', body: "공개 후 직접 삭제는 불가. 먼저 '공개 해제' 후에만 삭제할 수 있어요.",
        icon: Icons.warning_amber, tint: DuoColors.cardinal),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heroCard(),
        const SizedBox(height: 16),
        for (final s in _steps) ...[
          _stepRow(s),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        _startButton(context),
      ]),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEED4FF), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.beetle.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('CREATE A MISSION · 나만의 미션 만들기',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.beetleDeep)),
          SizedBox(height: 6),
          Text('Mission Designer',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.eel2)),
          SizedBox(height: 4),
          Text('당신만의 위치 기반 미션을 만들어 친구들과 공유해 보세요!',
              style: TextStyle(fontSize: 13, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        const Text('🤔', style: TextStyle(fontSize: 56)),
      ]),
    );
  }

  Widget _stepRow(({int id, String title, String body, IconData icon, Color tint}) s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: DuoColors.swan2, width: 2)),
      child: Row(children: [
        // 번호 원 (흰 테 3px + tint 60% inner stroke 1px)
        Stack(alignment: Alignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: s.tint, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: s.tint.withValues(alpha: 0.6), width: 1),
            ),
          ),
          Text('${s.id}', style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: Colors.white)),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
          const SizedBox(height: 2),
          Text(s.body, style: const TextStyle(fontSize: 12, color: DuoColors.wolf2)),
        ])),
        const SizedBox(width: 8),
        // 우측 큰 아이콘 박스 (64x64 tint 18% bg + tint icon)
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: s.tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Icon(s.icon, color: s.tint, size: 24, weight: 900),
        ),
      ]),
    );
  }

  /// SwiftUI candy 버튼 — beetle fill + beetleDeep 그림자 offset 4.
  Widget _startButton(BuildContext context) {
    return Stack(children: [
      Container(
        height: 56,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: DuoColors.beetleDeep, borderRadius: BorderRadius.circular(14)),
      ),
      Material(
        color: DuoColors.beetle,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onStartDesign,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.edit, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('미션 만들기 시작!',
                  style: TextStyle(
                      fontFamily: DuoFonts.display, fontSize: 14, color: Colors.white, letterSpacing: 0.84)),
            ]),
          ),
        ),
      ),
    ]);
  }
}
