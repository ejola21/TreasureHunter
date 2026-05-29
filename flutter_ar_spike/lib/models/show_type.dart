// models/show_type.dart — ShowType.swift 이식 (아이템 표시 방식).
enum ShowType {
  transparent('1'), // 지도·AR 모두 숨김 — 레이더로만
  arOnly('2'), // 지도 숨김, AR 정상 ("Hidden")
  mapOnly('3'), // 지도 표시, AR 거리·방향 숨김 ("Stealth")
  all('4'); // 지도·AR 모두 표시 ("Visible")

  final String code;
  const ShowType(this.code);

  static ShowType fromCode(String? c) =>
      ShowType.values.firstWhere((e) => e.code == c, orElse: () => ShowType.all);

  String get displayName => switch (this) {
        ShowType.all => 'Visible',
        ShowType.arOnly => 'Hidden',
        ShowType.mapOnly => 'Stealth',
        ShowType.transparent => 'Hidden+Stealth',
      };

  String get helpText => switch (this) {
        ShowType.all => '지도와 AR 화면에서 모두 표시',
        ShowType.arOnly => '지도에서 숨김 (AR 에서는 정상 표시)',
        ShowType.mapOnly => '지도에는 표시, AR 화면의 거리·방향 정보 숨김',
        ShowType.transparent => '지도와 AR 모두 숨김 (레이더 필요)',
      };

  /// 디자이너 picker 에 노출하는 케이스 (transparent 미노출).
  static const selectableCases = [ShowType.all, ShowType.arOnly, ShowType.mapOnly];

  bool isVisibleOnMap({required bool hasRadarMap, required bool hasRadarAll}) =>
      switch (this) {
        ShowType.all || ShowType.mapOnly => true,
        ShowType.arOnly || ShowType.transparent => hasRadarMap || hasRadarAll,
      };

  bool isVisibleInAR({required bool hasRadarAR, required bool hasRadarAll}) =>
      switch (this) {
        ShowType.all || ShowType.arOnly => true,
        ShowType.mapOnly || ShowType.transparent => hasRadarAR || hasRadarAll,
      };
}
