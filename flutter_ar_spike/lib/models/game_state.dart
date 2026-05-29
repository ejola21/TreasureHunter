// models/game_state.dart — GameState.swift 이식 (미션 상태/플레이 모드/필수 플래그).

/// 미션 공개 상태. 0=비공개, 2=공개 (1·3 폐기값은 unpublished 로 흡수).
enum MissionStatus {
  unpublished(0),
  published(2);

  final int value;
  const MissionStatus(this.value);

  static MissionStatus fromInt(int v) =>
      v == 2 ? MissionStatus.published : MissionStatus.unpublished;
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
