// models/game_state.dart — GameState.swift 이식 (미션 상태/플레이 모드/필수 플래그).

/// 미션 공개 상태 — 서버 R3.1 룰: 0 → 1 → 2 단방향만 허용.
/// - 0 unpublished: 편집 중 (디자이너 본인만)
/// - 1 testing:     테스트 완료, 공개 대기
/// - 2 published:   공개, Missions 탭 노출. 되돌리기 불가.
/// 알 수 없는 값 (legacy 3 등) → unpublished 로 흡수.
enum MissionStatus {
  unpublished(0),
  testing(1),
  published(2);

  final int value;
  const MissionStatus(this.value);

  static MissionStatus fromInt(int? v) {
    switch (v) {
      case 0: return MissionStatus.unpublished;
      case 1: return MissionStatus.testing;
      case 2: return MissionStatus.published;
      default: return MissionStatus.unpublished;
    }
  }

  /// 다음 진행 단계. published 면 null (더 못 올림).
  MissionStatus? get next {
    switch (this) {
      case MissionStatus.unpublished: return MissionStatus.testing;
      case MissionStatus.testing:     return MissionStatus.published;
      case MissionStatus.published:   return null;
    }
  }
}

/// 플레이 모드. 0=실제 GPS, 1=가상.
enum PlayMode {
  real(0),
  virtual(1);

  final int value;
  const PlayMode(this.value);

  static PlayMode fromInt(int v) => v == 1 ? PlayMode.virtual : PlayMode.real;
}

/// 필수 여부. 0=선택, 1=필수.
enum MandatoryFlag {
  optional(0),
  mandatory(1);

  final int value;
  const MandatoryFlag(this.value);

  static MandatoryFlag fromInt(int v) =>
      v == 1 ? MandatoryFlag.mandatory : MandatoryFlag.optional;
}
