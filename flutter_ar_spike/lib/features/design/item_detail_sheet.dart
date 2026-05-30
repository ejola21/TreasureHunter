// features/design/item_detail_sheet.dart — SwiftUI ItemDetailView + ItemForms 1:1.
// 정보 카드 + 💡 tip 카드 + itemType 별 폼 (16 SubForm) + 삭제 버튼.
// 16 SubForm 은 ItemType.mandatoryMode + showsShowType/showsItemGame/showsRelationId
// /showsEffectiveTime/infoLabel 매트릭스로 압축 (변경 시 매트릭스만 갱신).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../design_system/duo_tokens.dart';
import '../../models/game_state.dart';
import '../../models/item_quiz.dart';
import '../../models/item_type.dart';
import '../../models/item_type_detail.dart';
import '../../models/mission_item.dart';
import '../../models/show_type.dart';

/// 핀 탭 시 띄우는 디테일 시트. 변경된 MissionItem (취소 시 null) 반환.
Future<MissionItem?> showItemDetailSheet(BuildContext context, MissionItem original) {
  return showModalBottomSheet<MissionItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DuoColors.snow,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _ItemDetailSheet(original: original),
  );
}

class _ItemDetailSheet extends StatefulWidget {
  final MissionItem original;
  const _ItemDetailSheet({required this.original});

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  late MissionItem _item;
  late final TextEditingController _info;
  bool _deleteRequested = false;

  @override
  void initState() {
    super.initState();
    // 깊은 복사 (편집 중 상태가 원본에 즉시 반영되지 않도록).
    _item = MissionItem(
      missionID: widget.original.missionID,
      itemID: widget.original.itemID,
      mandatory: widget.original.mandatory,
      itemType: widget.original.itemType,
      latitude: widget.original.latitude,
      longitude: widget.original.longitude,
      blackCnt: widget.original.blackCnt,
      blackTime: widget.original.blackTime,
      rangeAR: widget.original.rangeAR,
      showType: widget.original.showType,
      effectiveRange: widget.original.effectiveRange,
      effectiveTime: widget.original.effectiveTime,
      itemGame: widget.original.itemGame,
      info: widget.original.info,
      relationItemID: widget.original.relationItemID,
      quizSeq: widget.original.quizSeq,
      rnpSeq: widget.original.rnpSeq,
      quizzes: widget.original.quizzes,
    );
    _info = TextEditingController(text: _item.info);
  }

  @override
  void dispose() {
    _info.dispose();
    super.dispose();
  }

  void _done() {
    _item.info = _info.text;
    Navigator.pop(context, _item);
  }

  void _delete() {
    _deleteRequested = true;
    HapticFeedback.heavyImpact();
    // 빈 ID(=0) MissionItem 를 반환해 호출부에서 "삭제 요청" 으로 인식.
    Navigator.pop(context, MissionItem(missionID: _item.missionID, itemID: -_item.itemID));
  }

  @override
  Widget build(BuildContext context) {
    final guide = _item.itemType.detailGuide;
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _toolbar(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoCard(guide),
              const SizedBox(height: 16),
              _tipCard(guide),
              const SizedBox(height: 16),
              _formCard(),
              const SizedBox(height: 16),
              _deleteButton(),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  /// 상단 toolbar: 취소 (macaw) / "아이템 상세" / 완료 (macaw heavy).
  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DuoColors.swan, width: 1)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: DuoColors.macaw, fontSize: 15)),
        ),
        const Expanded(
          child: Center(
            child: Text('아이템 상세',
                style: TextStyle(fontFamily: DuoFonts.display, fontSize: 16, color: DuoColors.eel2)),
          ),
        ),
        GestureDetector(
          onTap: _done,
          child: const Text('완료',
              style: TextStyle(color: DuoColors.macaw, fontSize: 15, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  /// 정보 카드: ItemPin 56 + "Item · 아이템" kicker + 라벨 + effect 텍스트.
  Widget _infoCard(ItemDetailGuide g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DuoColors.swan2, width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset(
            _item.mapIconName,
            width: 56, height: 56,
            errorBuilder: (_, _, _) => Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: DuoColors.swan2, shape: BoxShape.circle),
              child: const Icon(Icons.help_outline, color: DuoColors.eel2, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ITEM · 아이템',
                style: TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
            const SizedBox(height: 6),
            Text(_item.itemType.displayLabel,
                style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 18, color: DuoColors.eel2)),
            const SizedBox(height: 6),
            Text(g.effect, style: const TextStyle(fontSize: 13, color: DuoColors.wolf2, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    );
  }

  /// 💡 tip 카드 (beeBg + hex 0xE8C878 stroke).
  Widget _tipCard(ItemDetailGuide g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DuoColors.beeBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8C878), width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(g.tip,
                style: const TextStyle(fontSize: 12, color: DuoColors.beeDeep, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  /// 폼 카드 — SwiftUI iOS grouped Form 스타일 (섹션 헤더가 카드 *바깥 위*).
  Widget _formCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 섹션 헤더 — 카드 바깥 위 회색 작은 uppercase (iOS Form 스타일).
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Text(_item.itemType.formSectionTitle.toUpperCase(),
              style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 1.5, color: DuoColors.hare)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DuoColors.swan2, width: 2),
          ),
          child: Column(children: [
            // 필수 여부.
            _mandatoryField(),
            // 표시 방식.
            if (_item.itemType.showsShowType) ...[
              const _Divider(),
              _showTypeField(),
            ],
            // 발견 거리.
            const _Divider(),
            _rangeField(),
            // 부가 반경 라벨 (Mine: 폭발 반경, Dark: 다크존 반경).
            if (_extraRangeLabel() != null) _extraRangeRow(),
            // 미니게임.
            if (_item.itemType.showsItemGame) ...[
              const _Divider(),
              _itemGameField(),
            ],
            // 제한시간 (timeoutEnd).
            if (_item.itemType.showsEffectiveTime) ...[
              const _Divider(),
              _effectiveTimeField(),
            ],
            // 거리 (자동) — timeoutEnd 만, paired Start 와의 거리.
            if (_item.itemType == ItemType.timeoutEnd) ...[
              const _Divider(),
              _autoDistanceField(),
            ],
            // 페어 ID (timeout).
            if (_item.itemType.showsRelationId) ...[
              const _Divider(),
              _pairField(),
            ],
            // 안내 문구.
            if (_item.itemType.infoLabel != null) ...[
              const _Divider(),
              _infoField(_item.itemType.infoLabel!),
            ],
          ]),
        ),
        // Quiz 변형 섹션 (Quiz/Quiz20 한정).
        if (_item.itemType == ItemType.quiz || _item.itemType == ItemType.quiz20) ...[
          const SizedBox(height: 16),
          _quizVariantsSection(),
        ],
      ]),
    );
  }

  // Mine: 폭발 반경 / Dark: 다크존 반경 (rangeAR 와 동일 — 디스플레이 전용 강조 라벨).
  ({String label, Color color})? _extraRangeLabel() {
    if (_item.itemType == ItemType.mine) {
      return (label: '폭발 반경', color: DuoColors.foxDeep);
    }
    if (_item.itemType == ItemType.black) {
      return (label: '다크존 반경', color: Colors.black);
    }
    return null;
  }

  Widget _extraRangeRow() {
    final l = _extraRangeLabel()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Text('${l.label}: ${_item.rangeAR} m',
          style: TextStyle(fontSize: 13, color: l.color, fontWeight: FontWeight.w700)),
    );
  }

  /// timeoutEnd 의 거리 (자동) 표시 — 페어된 timeoutStart 와의 직선 거리. paired 데이터가 없으면 "—".
  Widget _autoDistanceField() {
    return _formRow(
      content: Row(children: [
        const Text('거리 (자동)', style: TextStyle(fontSize: 15, color: DuoColors.hare)),
        const Spacer(),
        Text(_item.effectiveRange > 0 ? '${_item.effectiveRange} m' : '—',
            style: const TextStyle(fontSize: 15, color: DuoColors.hare)),
      ]),
    );
  }

  /// Quiz 변형 섹션 — Section 헤더(개수 + ADD) + 변형 행 N개.
  Widget _quizVariantsSection() {
    final variants = _item.quizzes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 4, bottom: 6),
          child: Row(children: [
            Text('QUIZ 변형 (${variants.length}개)',
                style: const TextStyle(
                    fontFamily: DuoFonts.display,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: DuoColors.hare)),
            const Spacer(),
            InkWell(
              onTap: _addQuizVariant,
              child: Row(children: const [
                Icon(Icons.add_circle, size: 16, color: DuoColors.macaw),
                SizedBox(width: 4),
                Text('ADD',
                    style: TextStyle(
                        fontFamily: DuoFonts.display,
                        fontSize: 12,
                        color: DuoColors.macaw,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
              ]),
            ),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DuoColors.swan2, width: 2),
          ),
          child: variants.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('최소 1개의 변형을 추가하세요 (필수).',
                      style: TextStyle(fontSize: 12, color: DuoColors.cardinal)),
                )
              : Column(children: [
                  for (var i = 0; i < variants.length; i++) ...[
                    if (i > 0) const _Divider(),
                    _QuizVariantRow(
                      seq: variants[i].seq,
                      quiz: variants[i].quiz,
                      answer: variants[i].answer,
                      onChanged: (q, a) {
                        setState(() {
                          variants[i].quiz = q;
                          variants[i].answer = a;
                        });
                      },
                      onDelete: () =>
                          setState(() => variants.removeAt(i)),
                    ),
                  ],
                ]),
        ),
      ]),
    );
  }

  void _addQuizVariant() {
    final maxSeq = _item.quizzes.fold<int>(0, (a, q) => q.seq > a ? q.seq : a);
    setState(() {
      _item.quizzes.add(ItemQuiz(
        missionID: _item.missionID,
        itemID: _item.itemID,
        seq: maxSeq + 1,
      ));
    });
  }

  /// 공통 행 wrapper — iOS Form 행 스타일 (좌측 라벨, 우측 컨텐트, 하단 caption 회색).
  Widget _formRow({required Widget content, String? caption}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        content,
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(caption, style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
        ],
      ]),
    );
  }

  Widget _mandatoryField() {
    final mode = _item.itemType.mandatoryMode;
    switch (mode) {
      case MandatoryMode.yes:
        return _formRow(
          content: Row(children: const [
            Text('필수 여부', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
            Spacer(),
            Text('자동 — 켜짐', style: TextStyle(fontSize: 15, color: DuoColors.green500, fontWeight: FontWeight.w600)),
          ]),
          caption: '이 아이템은 미션 진행에 꼭 필요해 자동으로 필수 처리돼요.',
        );
      case MandatoryMode.no:
        return _formRow(
          content: Row(children: const [
            Text('필수 여부', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
            Spacer(),
            Text('자동 — 꺼짐', style: TextStyle(fontSize: 15, color: DuoColors.hare, fontWeight: FontWeight.w600)),
          ]),
          caption: '이 아이템은 미션 완료에 영향을 주지 않아요.',
        );
      case MandatoryMode.toggle:
        return _formRow(
          content: Row(children: [
            const Text('필수 여부', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
            const Spacer(),
            Switch.adaptive(
              value: _item.isMandatory,
              activeThumbColor: DuoColors.green500,
              onChanged: (v) => setState(() => _item.mandatory = v ? MandatoryFlag.mandatory : MandatoryFlag.optional),
            ),
          ]),
          caption: '미션을 끝내려면 꼭 얻어야 하는 아이템인지 정해요.',
        );
    }
  }

  /// 표시 방식 — iOS Form Picker 스타일 (좌측 라벨 + 우측 현재값 + chevron, 탭 → 메뉴).
  Widget _showTypeField() {
    return _formRow(
      content: InkWell(
        onTap: () async {
          final picked = await _pickFromMenu<ShowType>(
            current: _item.showType,
            options: ShowType.selectableCases.map((s) => (s, s.displayName)).toList(),
          );
          if (picked != null) setState(() => _item.showType = picked);
        },
        child: Row(children: [
          const Text('표시 방식', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
          const Spacer(),
          Text(_item.showType.displayName, style: const TextStyle(fontSize: 15, color: DuoColors.hare)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: DuoColors.hare),
        ]),
      ),
      caption: _item.showType.helpText,
    );
  }

  /// 발견 거리 — SwiftUI Stepper(+/-) 1:1 (5~500, step 5).
  Widget _rangeField() {
    return _formRow(
      content: Row(children: [
        const Text('발견 거리', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
        const Spacer(),
        Text('${_item.rangeAR} m',
            style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel2)),
        const SizedBox(width: 10),
        _StepperBtns(
          onMinus: _item.rangeAR > 5
              ? () => setState(() => _item.rangeAR = (_item.rangeAR - 5).clamp(5, 500))
              : null,
          onPlus: _item.rangeAR < 500
              ? () => setState(() => _item.rangeAR = (_item.rangeAR + 5).clamp(5, 500))
              : null,
        ),
      ]),
      caption: 'AR 화면에서 아이템이 표시되는 유효 반경.',
    );
  }

  Widget _itemGameField() {
    const games = [(0, '없음'), (1, '흔들기 게임'), (2, '터치 게임 (준비 중)'), (3, '랜덤 게임 (준비 중)')];
    return _formRow(
      content: InkWell(
        onTap: () async {
          final picked = await _pickFromMenu<int>(current: _item.itemGame, options: games);
          if (picked != null) setState(() => _item.itemGame = picked);
        },
        child: Row(children: [
          const Text('미니게임', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
          const Spacer(),
          Text(games.firstWhere((e) => e.$1 == _item.itemGame, orElse: () => games.first).$2,
              style: const TextStyle(fontSize: 15, color: DuoColors.hare)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: DuoColors.hare),
        ]),
      ),
      caption: '아이템 획득 시 필요한 게임을 추가할 수 있어요.',
    );
  }

  Widget _pairField() {
    return _formRow(
      content: Row(children: [
        const Text('페어 ID', style: TextStyle(fontSize: 15, color: DuoColors.hare)),
        const Spacer(),
        Text(_item.relationItemID > 0 ? '#${_item.relationItemID}' : '—',
            style: const TextStyle(fontSize: 15, color: DuoColors.hare)),
      ]),
    );
  }

  Widget _effectiveTimeField() {
    return _formRow(
      content: Row(children: [
        const Text('제한 시간', style: TextStyle(fontSize: 15, color: DuoColors.eel)),
        const Spacer(),
        Text('${_item.effectiveTime}초',
            style: const TextStyle(fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel2)),
        const SizedBox(width: 10),
        _StepperBtns(
          onMinus: _item.effectiveTime > 1
              ? () => setState(() => _item.effectiveTime = (_item.effectiveTime - 5).clamp(1, 3600))
              : null,
          onPlus: _item.effectiveTime < 3600
              ? () => setState(() => _item.effectiveTime = (_item.effectiveTime + 5).clamp(1, 3600))
              : null,
        ),
      ]),
    );
  }

  Widget _infoField(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: DuoColors.hare)),
        const SizedBox(height: 4),
        TextField(
          controller: _info,
          minLines: 2, maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DuoColors.swan2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DuoColors.swan2)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 4),
        const Text('아이템을 얻은 순간 알림에 보여줄 문구를 적어요.',
            style: TextStyle(fontSize: 11, color: DuoColors.hare)),
      ]),
    );
  }

  /// iOS Picker 모방 — 옵션 선택 메뉴 시트.
  Future<T?> _pickFromMenu<T>({required T current, required List<(T, String)> options}) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < options.length; i++) ...[
            InkWell(
              onTap: () => Navigator.pop(ctx, options[i].$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Expanded(child: Text(options[i].$2,
                      style: TextStyle(fontSize: 16, color: options[i].$1 == current ? DuoColors.macaw : DuoColors.eel2,
                          fontWeight: options[i].$1 == current ? FontWeight.w700 : FontWeight.normal))),
                  if (options[i].$1 == current)
                    const Icon(Icons.check, color: DuoColors.macaw, size: 20),
                ]),
              ),
            ),
            if (i < options.length - 1) const Divider(height: 1, color: DuoColors.swan),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  /// 빨간 outline 삭제 버튼 — SwiftUI Cardinal 색 + trash 아이콘.
  Widget _deleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, color: DuoColors.cardinal, size: 18),
          label: const Text('아이템 삭제',
              style: TextStyle(fontFamily: DuoFonts.display, fontSize: 14, color: DuoColors.cardinal, letterSpacing: 0.84)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: DuoColors.cardinal, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DuoRadius.lg)),
            backgroundColor: Colors.white,
          ),
          onPressed: _deleteRequested ? null : _delete,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: DuoColors.swan, margin: const EdgeInsets.symmetric(horizontal: 14));
}

/// Quiz 변형 한 줄 — #seq + 질문/정답 TextField + 삭제 아이콘. SwiftUI QuizVariantRow 1:1.
class _QuizVariantRow extends StatefulWidget {
  final int seq;
  final String quiz;
  final String answer;
  final void Function(String quiz, String answer) onChanged;
  final VoidCallback onDelete;
  const _QuizVariantRow({
    required this.seq,
    required this.quiz,
    required this.answer,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_QuizVariantRow> createState() => _QuizVariantRowState();
}

class _QuizVariantRowState extends State<_QuizVariantRow> {
  late final TextEditingController _q;
  late final TextEditingController _a;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.quiz)
      ..addListener(() => widget.onChanged(_q.text, _a.text));
    _a = TextEditingController(text: widget.answer)
      ..addListener(() => widget.onChanged(_q.text, _a.text));
  }

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: DuoColors.hare, fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DuoColors.swan2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DuoColors.swan2)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${widget.seq}',
                style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
            const SizedBox(height: 4),
            TextField(
                controller: _q, minLines: 1, maxLines: 3, decoration: deco('퀴즈 질문')),
            const SizedBox(height: 6),
            TextField(controller: _a, decoration: deco('정답')),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: DuoColors.cardinal),
          onPressed: widget.onDelete,
          tooltip: '변형 삭제',
        ),
      ]),
    );
  }
}

/// SwiftUI Stepper 동등 — [-][+] 라운드 버튼 2개 (DuoTokens swan2 배경 + macaw 텍스트).
class _StepperBtns extends StatelessWidget {
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const _StepperBtns({this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _Btn(icon: Icons.remove, onTap: onMinus),
      const SizedBox(width: 1),
      _Btn(icon: Icons.add, onTap: onPlus),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 32,
        decoration: BoxDecoration(
          color: disabled ? DuoColors.swan2.withValues(alpha: 0.5) : DuoColors.swan2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: disabled ? DuoColors.hare : DuoColors.macawDeep, weight: 900),
      ),
    );
  }
}
