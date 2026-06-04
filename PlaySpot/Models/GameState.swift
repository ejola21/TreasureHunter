// Models/GameState.swift
import Foundation

/// 미션 공개 상태.
/// - `unpublished` (0): 비공개 — Missions 탭(공개 목록)에 노출되지 않음. 본인 디자인 목록에만 보임.
/// - `published`   (2): 공개 — Missions 탭에 노출.
///
/// 서버는 3단계 전이 룰 강제: `0 → 1 → 2` 단방향 (역방향/점프 금지).
/// - `unpublished`(0): 편집 중 — 디자이너 본인만 보임
/// - `testing`(1): 테스트 완료 — 공개 대기 (디자이너가 직접 플레이 검증 후)
/// - `published`(2): 공개 — Missions 탭에 노출. **되돌리기 불가**
/// 서버에서 알 수 없는 값(legacy `3` 등) 이 내려오면 `.unpublished` 로 흡수.
enum MissionStatus: Int, Codable {
    case unpublished = 0
    case testing = 1
    case published = 2

    /// 다음 단계 (publish 진행 방향). published 면 nil — 더 이상 못 올림.
    var next: MissionStatus? {
        switch self {
        case .unpublished: return .testing
        case .testing:     return .published
        case .published:   return nil
        }
    }
}

enum PlayMode: Int, Codable {
    case real = 0           // REAL_MODE
    case virtual = 1        // VIRTUAL_MODE
}

enum MandatoryFlag: Int, Codable {
    case optional = 0       // MANDATORY_N
    case mandatory = 1      // MANDATORY_Y
}
