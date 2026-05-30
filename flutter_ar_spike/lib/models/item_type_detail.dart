// models/item_type_detail.dart — SwiftUI ItemType.detailGuide (effect, tip) 이식.
import 'item_type.dart';

class ItemDetailGuide {
  final String effect;
  final String tip;
  const ItemDetailGuide(this.effect, this.tip);
}

extension ItemDetailExt on ItemType {
  ItemDetailGuide get detailGuide => switch (this) {
        ItemType.start => const ItemDetailGuide(
            '미션이 시작되는 출발점이에요. 플레이어가 이 위치를 찍어야 시간이 흐르기 시작합니다.',
            '미션에 꼭 1개. 안내문에 "여기서 출발하세요!" 같은 한 줄을 넣어주면 좋아요.'),
        ItemType.end => const ItemDetailGuide(
            '미션이 끝나는 도착점이에요. 필수 아이템을 모두 모은 뒤 여기에 도달하면 미션 클리어!',
            '미션에 꼭 1개. 시작점에서 적당히 떨어진, 마지막에 들를 만한 위치에.'),
        ItemType.quiz || ItemType.quiz20 => const ItemDetailGuide(
            '획득하면 퀴즈 창이 떠요. 정답을 맞혀야 획득됩니다.',
            '여러 문제를 등록하면 플레이 시 랜덤으로 출제돼요.'),
        ItemType.timeoutStart => const ItemDetailGuide(
            '획득하는 순간 짧은 카운트다운이 시작돼요. 시간 안에 \'Run End\' 아이템을 획득해야 합니다.',
            '\'Run End\' 아이템이 자동으로 함께 생겨요. 제한 시간을 30~120초로 설정해 난이도를 조절하세요.'),
        ItemType.timeoutEnd => const ItemDetailGuide(
            'Run Start 의 짝꿍이에요. 제한 시간 안에 획득하면 성공입니다.',
            '자동으로 생성되니 따로 추가할 필요 없어요. 위치만 옮기면 됩니다.'),
        ItemType.mineNoBomb => const ItemDetailGuide(
            '획득하면 지뢰 한 번의 피해를 막아주는 방어 아이템이에요.',
            '안내문에 "지뢰 피해를 1번 막아드려요" 정도 넣어주세요.'),
        ItemType.solution => const ItemDetailGuide(
            '획득하면 퀴즈 1개의 답을 알려줍니다.', '미니게임을 추가해서 획득 난이도를 조절하세요.'),
        ItemType.radarAR => const ItemDetailGuide(
            '획득 후 AR 화면에서 숨겨둔 아이템들이 보이게 돼요.',
            '미션에 1개만. Stealth 아이템과 함께 사용하세요.'),
        ItemType.radarMap => const ItemDetailGuide(
            '획득 후 지도 화면에서 숨겨둔 아이템들이 보이게 돼요.',
            '미션에 1개만. Hidden 아이템과 함께 사용하세요.'),
        ItemType.radarMine => const ItemDetailGuide(
            '획득 후 지도에 지뢰 위치와 폭발 반경이 표시돼요.',
            '미션에 1개만. 지뢰가 많은 코스라면 꼭 하나 두는 걸 추천!'),
        ItemType.radarAll => const ItemDetailGuide(
            '획득 후 모든 숨겨진 아이템이 표시돼요.', '미션에 1개만.'),
        ItemType.mine => const ItemDetailGuide(
            '위험! 반경 안에 들어가면 폭발하면서 최근에 얻은 아이템 1개를 잃어요.',
            '반경(rangeAR)만 설정하면 끝. 좁은 길목·핵심 동선에 두면 긴장감이 살아납니다. 지도에 빨간 원으로 표시돼요.'),
        ItemType.black => const ItemDetailGuide(
            'AR 보물찾기 존이에요. 지도 반경 안에서는 아이템 표시가 안 돼요.',
            '보물찾기 분위기를 만들고 싶은 구역에 활용하세요.'),
        ItemType.simple => const ItemDetailGuide(
            '획득하면 힌트 문구가 보이는 안내 아이템이에요.',
            '미니게임을 추가해 난이도 조절 가능해요. 미션 완료에 대한 힌트나 안내문을 표시해요.'),
        ItemType.random => const ItemDetailGuide(
            '획득하면 다른 아이템 중 하나를 랜덤으로 함께 획득할 수 있어요. (행운 ✨)',
            '미션 곳곳에 흩뿌려두면 재미가 살아나요. 안내문 한 줄과 미니게임 선택 가능.'),
        ItemType.coupon => const ItemDetailGuide(
            '획득하면 쿠폰 코드/안내문이 알림으로 떠요.',
            '\'info\' 칸에 실제 쿠폰 코드나 사용 안내를 적으세요. 예: "이마트 5000원 할인 ABCD-1234"'),
        ItemType.store => const ItemDetailGuide(
            '미션 중 상점 진입점으로 쓸 예정인 아이템이에요. 지금은 효과가 없습니다.',
            '향후 결제/포인트 화면 연동 예정. 현재는 배치해도 게임 중 알림이 뜨지 않으니 사용을 미뤄주세요.'),
        _ => const ItemDetailGuide('일반 아이템이에요.', '이 아이템 유형은 빌더에서 활용하지 않습니다.'),
      };

  /// SwiftUI ItemForms 의 SubForm 별 섹션 헤더 라벨.
  String get formSectionTitle => switch (this) {
        ItemType.start => 'Start 아이템',
        ItemType.end => 'End 아이템',
        ItemType.simple => 'Hint 아이템',
        ItemType.quiz || ItemType.quiz20 => 'Quiz 아이템',
        ItemType.timeoutStart => 'Run Start (타임 시작)',
        ItemType.timeoutEnd => 'Run End (타임 종료)',
        ItemType.mine => 'Mine (지뢰)',
        ItemType.black => 'Dark (다크존)',
        ItemType.mineNoBomb => 'Defense (방어)',
        ItemType.random => 'Gambling (랜덤)',
        ItemType.solution => 'Solution (솔루션)',
        ItemType.radarAR => 'Stealth Radar',
        ItemType.radarMap => 'Map Radar',
        ItemType.radarMine => 'Mine Radar',
        ItemType.radarAll => 'All Radar',
        ItemType.coupon => 'Coupon (쿠폰)',
        ItemType.store => 'Store (상점)',
        _ => displayLabel,
      };

  /// 필수 처리 모드.
  ///   yes: 자동 켜짐 (편집 불가) — start/end/quiz/runStart/runEnd
  ///   no: 자동 꺼짐 (편집 불가) — mine/black/solution/store
  ///   toggle: 사용자가 선택 — simple/defense/gambling/radar*/coupon
  MandatoryMode get mandatoryMode => switch (this) {
        ItemType.start ||
        ItemType.end ||
        ItemType.quiz ||
        ItemType.quiz20 ||
        ItemType.timeoutStart ||
        ItemType.timeoutEnd =>
          MandatoryMode.yes,
        ItemType.mine || ItemType.black || ItemType.solution || ItemType.store =>
          MandatoryMode.no,
        _ => MandatoryMode.toggle,
      };

  /// 표시 방식 (showType) 노출 여부.
  bool get showsShowType => !{
        ItemType.mine, ItemType.black, ItemType.solution, ItemType.store
      }.contains(this);

  /// 미니게임 노출 여부.
  bool get showsItemGame => {
        ItemType.simple,
        ItemType.mineNoBomb,
        ItemType.random,
        ItemType.solution,
        ItemType.coupon,
      }.contains(this);

  /// 안내 문구 (info) 노출 여부 + 라벨.
  String? get infoLabel => switch (this) {
        ItemType.start => '시작 안내문',
        ItemType.end => '종료 안내문',
        ItemType.simple => '힌트 텍스트',
        ItemType.coupon => '쿠폰 코드/안내문',
        ItemType.mine ||
        ItemType.black ||
        ItemType.solution ||
        ItemType.store ||
        ItemType.quiz ||
        ItemType.quiz20 =>
          null, // info 안 받음
        _ => '안내 문구',
      };

  /// 페어링 ID 노출 (timeoutStart/timeoutEnd 만).
  bool get showsRelationId => this == ItemType.timeoutStart || this == ItemType.timeoutEnd;

  /// 제한시간(effectiveTime) 입력 노출 (timeoutEnd 만).
  bool get showsEffectiveTime => this == ItemType.timeoutEnd;
}

enum MandatoryMode { yes, no, toggle }
