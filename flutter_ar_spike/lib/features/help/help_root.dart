// features/help/help_root.dart — SwiftUI Help/* 4 파일 통합 이식.
// HelpRoot (라우터, 3 탭) + HelpItemsView + HelpHowToView + HelpDesignView.
// FoxMascot/ItemPin 일러스트는 emoji/IconData 로 대체.
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';
import '../../models/item_type.dart';

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
          _tabs(),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_tab) {
                HelpTab.items => const _HelpItemsView(),
                HelpTab.howto => const _HelpHowToView(),
                HelpTab.design => _HelpDesignView(onStart: widget.onStartDesign),
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: DuoColors.swan2, borderRadius: BorderRadius.circular(12)),
        child: Row(children: HelpTab.values.map((t) {
          final on = t == _tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? DuoColors.macaw : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(_label(t),
                    style: TextStyle(
                      fontFamily: DuoFonts.display, fontSize: 12,
                      color: on ? Colors.white : DuoColors.eel2,
                    )),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }
}

// ─── §14 Item Glossary ───────────────────────────────────────────────
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

  String _effect() => switch (type) {
        ItemType.start => '미션 시작점',
        ItemType.end => '미션 종료점 — 필수 아이템 다 모으면 클리어',
        ItemType.simple => '힌트 또는 미니게임',
        ItemType.mine => '범위 들어가면 폭발, 최근 획득 1개 손실',
        ItemType.mineNoBomb => 'Defense — 지뢰 폭발 1회 흡수',
        ItemType.random => 'Gambling — 무작위 다른 아이템 1개 획득',
        ItemType.quiz || ItemType.quiz20 => '정답을 맞춰야 획득',
        ItemType.solution => '퀴즈 답을 알 수 있게 해주는 보조 아이템',
        ItemType.radarMap => 'Hidden 아이템을 지도에서 보이게',
        ItemType.radarAR => 'Stealth 아이템을 AR에서 보이게',
        ItemType.radarMine => '지뢰 범위를 지도에 표시',
        ItemType.radarAll => '모든 숨김 아이템 한 번에 공개',
        ItemType.black => 'Dark zone — 범위 안 아이템 숨김',
        ItemType.coupon => '쿠폰 정보 표시',
        ItemType.store => '상점 (미구현)',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 핀 (real PNG asset 사용)
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
          Text(_effect(), style: const TextStyle(fontSize: 11, color: DuoColors.wolf2)),
        ])),
      ]),
    );
  }
}

// ─── §15 How To Play ─────────────────────────────────────────────────
class _HelpHowToView extends StatelessWidget {
  const _HelpHowToView();

  static const _steps = [
    (id: 1, title: '미션 선택', body: '내 주변/인기/신규 미션 중에서 골라요.', icon: Icons.map, tint: DuoColors.macaw),
    (id: 2, title: '근처로 이동', body: 'GPS로 거리를 확인하면서 가까이 다가가요.', icon: Icons.location_on, tint: DuoColors.fox),
    (id: 3, title: '아이템 획득', body: 'AR에서 흔들거나 탭해서 아이템을 모아요.', icon: Icons.touch_app, tint: DuoColors.green500),
    (id: 4, title: '미션 완료', body: '필수 아이템을 모두 모으면 클리어 + 보상!', icon: Icons.emoji_events, tint: DuoColors.bee),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hero(),
        const SizedBox(height: 16),
        _modeCards(),
        const SizedBox(height: 16),
        _stepsList(),
        const SizedBox(height: 16),
        _rewardStrip(),
      ]),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [DuoColors.foxBg, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.fox.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('HOW TO PLAY · 시작하기',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.foxDeep)),
          SizedBox(height: 6),
          Text('Quick Start',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.eel2)),
          SizedBox(height: 4),
          Text('4단계로 미션을 시작해보세요!',
              style: TextStyle(fontSize: 13, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
        ])),
        const Text('🎯', style: TextStyle(fontSize: 56)),
      ]),
    );
  }

  Widget _modeCards() {
    return Row(children: [
      Expanded(child: _modeCard(kicker: 'LIVE', title: '리얼 모드', desc: '실제 GPS로 직접 걸으면서 플레이', tint: DuoColors.green500, bg: DuoColors.green100)),
      const SizedBox(width: 10),
      Expanded(child: _modeCard(kicker: 'HOME', title: '가상 모드', desc: '집에서도 위치를 시뮬레이션해 즐기기', tint: DuoColors.beetle, bg: const Color(0xFFF1DCFF))),
    ]);
  }

  Widget _modeCard({required String kicker, required String title, required String desc, required Color tint, required Color bg}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: tint, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ─── §16 Design (미션 디자이너) ───────────────────────────────────────
class _HelpDesignView extends StatelessWidget {
  final VoidCallback? onStart;
  const _HelpDesignView({this.onStart});

  static const _steps = [
    (id: 1, title: '장소 선택', body: '미션이 펼쳐질 지도 위치를 정해요.', icon: Icons.place, tint: DuoColors.beetle),
    (id: 2, title: '아이템 배치', body: '핀을 찍어 시작·종료·퀴즈 아이템을 놓아요.', icon: Icons.add_location, tint: DuoColors.macaw),
    (id: 3, title: '난이도 조정', body: '범위·시간·필수 여부 등을 설정해요.', icon: Icons.tune, tint: DuoColors.fox),
    (id: 4, title: '공개 설정', body: '저장 후 공개하면 다른 플레이어가 만날 수 있어요.', icon: Icons.public, tint: DuoColors.green500),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hero(),
        const SizedBox(height: 16),
        for (final s in _steps) ...[
          _stepRow(s),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        _startButton(context),
      ]),
    );
  }

  Widget _hero() {
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
        const Text('🤔', style: TextStyle(fontSize: 56)),
      ]),
    );
  }

  Widget _stepRow(({int id, String title, String body, IconData icon, Color tint}) s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: DuoColors.swan2, width: 2)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: s.tint, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: s.tint.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          alignment: Alignment.center,
          child: Text('${s.id}', style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.title, style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.eel2)),
          const SizedBox(height: 2),
          Text(s.body, style: const TextStyle(fontSize: 12, color: DuoColors.wolf2)),
        ])),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: s.tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
          child: Icon(s.icon, color: s.tint, size: 24, weight: 900),
        ),
      ]),
    );
  }

  Widget _startButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onStart?.call();
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: DuoColors.beetle, borderRadius: BorderRadius.circular(14)),
        child: const Text('미션 만들기 시작!',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: Colors.white, letterSpacing: 0.84)),
      ),
    );
  }
}
