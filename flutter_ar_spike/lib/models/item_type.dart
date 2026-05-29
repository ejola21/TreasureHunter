// models/item_type.dart — ItemType.swift 이식 (아이템 타입 enum + 아이콘 경로).
enum ItemType {
  num00('00'), num01('01'), num02('02'), num03('03'), num04('04'),
  num05('05'), num06('06'), num07('07'), num08('08'), num09('09'),
  alphabet('10'),
  quiz('40'), quiz20('41'), timeoutStart('42'), timeoutEnd('43'),
  end('48'), start('49'),
  random('50'), simple('51'), solution('52'), penaltyRemove('54'),
  mine('55'), black('56'), coupon('59'), mineNoBomb('61'),
  radarAR('65'), radarMap('66'), radarAll('67'), radarMine('68'), radarBlack('69'),
  store('91');

  final String code;
  const ItemType(this.code);

  static ItemType fromCode(String? c) =>
      ItemType.values.firstWhere((e) => e.code == c, orElse: () => ItemType.simple);

  /// AR 화면 좌측 라벨 등 (ItemType.displayLabel).
  String get displayLabel => switch (this) {
        ItemType.start => 'Start',
        ItemType.end => 'End',
        ItemType.simple => 'Hint',
        ItemType.quiz || ItemType.quiz20 => 'Quiz',
        ItemType.random => 'Gambling',
        ItemType.timeoutStart => 'Run Start',
        ItemType.timeoutEnd => 'Run End',
        ItemType.mine => 'Mine',
        ItemType.black => 'Dark',
        ItemType.mineNoBomb => 'Defense',
        ItemType.solution => 'Solution',
        ItemType.radarAR => 'Stealth Radar',
        ItemType.radarMap => 'Map Radar',
        ItemType.radarAll => 'All Radar',
        ItemType.radarMine => 'Mine Radar',
        ItemType.coupon => 'Coupon',
        ItemType.store => 'Store',
        _ => 'Item',
      };

  /// 리소스 이미지 파일명 접두사 (imageFileName).
  String get imageFileName => switch (this) {
        ItemType.start => 'start',
        ItemType.end => 'end',
        ItemType.simple => 'simple',
        ItemType.quiz || ItemType.quiz20 => 'quiz',
        ItemType.random => 'random_box',
        ItemType.timeoutStart => 'time_start',
        ItemType.timeoutEnd => 'time_end',
        ItemType.mine => 'mine',
        ItemType.black => 'black',
        ItemType.mineNoBomb => 'mine_nobomb',
        ItemType.solution => 'genius',
        ItemType.radarAR => 'radar_ar',
        ItemType.radarMap => 'radar_map',
        ItemType.radarMine => 'radar_mine',
        ItemType.radarAll => 'radar_all',
        ItemType.coupon => 'coupon',
        ItemType.store => 'store',
        _ => 'original',
      };

  /// 지도 아이콘 에셋 경로 (assets/items/...). mandatory 면 in_, 아니면 i_.
  String mapIcon({required bool mandatory}) =>
      mandatory ? 'assets/items/in_$imageFileName.png' : 'assets/items/i_$imageFileName.png';

  /// AR 아이콘 에셋 경로 (assets/ar/...). mandatory 면 arn_, 아니면 ar_.
  String arIcon({required bool mandatory}) =>
      mandatory ? 'assets/ar/arn_$imageFileName.png' : 'assets/ar/ar_$imageFileName.png';

  bool get isMine => this == ItemType.mine || this == ItemType.mineNoBomb;
  bool get isRadar =>
      this == ItemType.radarAR || this == ItemType.radarMap || this == ItemType.radarAll || this == ItemType.radarMine;
  bool get isTimeout => this == ItemType.timeoutStart || this == ItemType.timeoutEnd;
}
